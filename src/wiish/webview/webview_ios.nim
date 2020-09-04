## Module for making iOS Webview applications.
when not defined(ios):
  {.fatal: "webview_ios only works with ios".}

{.passL: "-framework UIKit" .}
{.passL: "-framework WebKit" .}
{.emit: """
#include <UIKit/UIKit.h>
#include <WebKit/WebKit.h>
""".}

import darwin/objc/runtime

import macros
import times
import os
import strformat
import logging
import json

import ../events
export events
import ../logsetup
import ../baseapp
export baseapp
import ./base
export base
  
type
  WebviewIosApp* = ref object of RootObj
    window*: WebviewIosWindow
    life*: MobileLifecycle
  
  WebviewIosWindow* = ref object of RootObj
    onReady*: EventSource[bool]
    onMessage*: EventSource[string]
    wiishController*: pointer

proc newWebviewMobileApp*(): WebviewIosApp =
  new(result)
  new(result.window)
  result.life = newMobileLifecycle()

proc evalJavaScript*(win:WebviewIosWindow, js:string) =
  ## Evaluate some JavaScript in the webview
  var
    controller = win.wiishController
    javascript:cstring = js
  {.emit: """
  [controller evalJavaScript:[NSString stringWithUTF8String:javascript]];
  """.}

proc sendMessage*(win:WebviewIosWindow, message:string) =
  ## Send a message from Nim to JS
  evalJavaScript(win, &"wiish._handleMessage({%message});")

#-----------------------------------------------------------
# main()
#-----------------------------------------------------------

template start*(app: WebviewIosApp, url: string) =
  ## Start the webview app at the given URL.

  when not compileOption("noMain"):
    {.error: "Please run Nim with --noMain flag.".}

  proc nimwin() : WebviewIosWindow {.exportc.} = app.window

  proc jsbridgecode() : cstring {.exportc.} =
    """
    const readyrunner = {
      set: function(obj, prop, value) {
        if (prop === 'onReady') {
          value();
          window.webkit.messageHandlers.wiish_internal_ready.postMessage('');
        }
        obj[prop] = value;
        return true;
      }
    };
    let onReadyFunc;
    if (window.wiish && window.wiish.onReady) {
      onReadyFunc = window.wiish.onReady;
    }
    window.wiish = new Proxy({}, readyrunner);
    window.wiish.handlers = [];
    /**
      * Called by Nim code to transmit a message to JS.
      */
    window.wiish._handleMessage = function(message) {
      for (let i = 0; i < wiish.handlers.length; i++) {
        wiish.handlers[i](message);
      }
    };

    /**
      *  Called by JS application code to watch for messages
      *  from Nim
      */
    window.wiish.onMessage = function(handler) {
      wiish.handlers.push(handler);
    };
    
    /**
      *  Called by JS application code to send messages to Nim
      */
    window.wiish.sendMessage = function(message) {
      window.webkit.messageHandlers.wiish.postMessage(message);
    };
    if (onReadyFunc) { window.wiish.onReady = onReadyFunc; }
    """

  proc doLog(x:cstring) {.exportc.} =
    debug(x)
  proc nim_didFinishLaunching() {.exportc.} =
    debug "didFinishLaunching"
    app.life.onCreate.emit(true)
  proc nim_applicationWillResignActive() {.exportc.} =
    debug "applicationWillResignActive"
    app.life.onPause.emit(true)
  proc nim_applicationDidEnterBackground() {.exportc.} =
    debug "applicationDidEnterBackground"
    app.life.onStop.emit(true)
  proc nim_applicationWillEnterForeground() {.exportc.} =
    debug "applicationWillEnterForeground"
    app.life.onResume.emit(true)
  proc nim_applicationDidBecomeActive() {.exportc.} =
    debug "applicationDidBecomeActive"
    app.life.onStart.emit(true)
  proc nim_applicationWillTerminate() {.exportc.} =
    debug "applicationWillTerminate"
    app.life.onDestroy.emit(true)
  
  proc nim_signalJSMessagesReady() {.exportc.} =
    debug "nim_signalJSMessagesReady"
    app.window.onReady.emit(true)
  proc nim_sendMessageToNim(x:cstring) {.exportc.} =
    debug "nim_sendMessageToNim: " & $x
    app.window.onMessage.emit($x)
  
  proc getInitURL(): cstring {.exportc.} = url

  {.emit: """
  //#include <UIKit/UIKit.h>
  //#include <WebKit/WebKit.h>

  // WiishController
  @interface WiishController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler> {
    WKWebView* webView;
  }
  - (void)evalJavaScript:(NSString *)jscript;
  @end
  @implementation WiishController {
  }
  - (void)evalJavaScript:(NSString *)jscript {
    [webView evaluateJavaScript:jscript completionHandler:nil];
  }
  - (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (message.name == @"wiish_internal_ready") {
      nim_signalJSMessagesReady();
    } else {
      nim_sendMessageToNim([message.body UTF8String]);
    }
  }
  - (void)viewDidLoad {
    [super viewDidLoad];
    nimwin()->wiishController = self;

    // Prepare JS/Nim bridge
    NSString *javascript = [NSString stringWithUTF8String:jsbridgecode()];
    WKUserScript *userScript = [[WKUserScript alloc]
      initWithSource:javascript
      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
      forMainFrameOnly:NO
    ];

    self.view = [[UIView alloc] initWithFrame:self.view.frame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;
    self.view.backgroundColor = [UIColor greenColor];
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    [theConfiguration.userContentController addScriptMessageHandler:self name:@"wiish"];
    [theConfiguration.userContentController addScriptMessageHandler:self name:@"wiish_internal_ready"];
    [theConfiguration.userContentController addUserScript:userScript];

    webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:theConfiguration];
    webView.navigationDelegate = self;
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.autoresizesSubviews = YES;
    webView.scrollView.bounces = false;
    NSURL *nsurl=[NSURL URLWithString: [NSString stringWithUTF8String:getInitURL()]];
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
    [webView loadRequest:nsrequest];
    [self.view addSubview:webView];
    return;
  }
  @end

  @interface AppDelegate : UIResponder <UIApplicationDelegate>
  @property (strong, nonatomic) UIWindow *window;
  @end

  @implementation AppDelegate
  - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
      // Override point for customization after application launch.
      self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
      self.window.rootViewController = [[WiishController alloc] init];
      self.window.backgroundColor = [UIColor blueColor];
      [self.window makeKeyAndVisible];
      nim_didFinishLaunching();
      return YES;
  }
  - (void)applicationWillResignActive:(UIApplication *)application {
      // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
      // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
      nim_applicationWillResignActive();
  }
  - (void)applicationDidEnterBackground:(UIApplication *)application {
      // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
      // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
      nim_applicationDidEnterBackground();
  }
  - (void)applicationWillEnterForeground:(UIApplication *)application {
      // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
      nim_applicationWillEnterForeground();
  }
  - (void)applicationDidBecomeActive:(UIApplication *)application {
      // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
      nim_applicationDidBecomeActive();
  }
  - (void)applicationWillTerminate:(UIApplication *)application {
      // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
      nim_applicationWillTerminate();
  }
  @end

  N_CDECL(void, NimMain)(void);
  int main(int argc, char * argv[]) {
      @autoreleasepool {
          NimMain();
          return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
      }
  }
  """ .}
