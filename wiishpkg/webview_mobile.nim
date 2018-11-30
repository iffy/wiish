## Module for making mobile Webview applications.
import macros
import times
import strformat
import darwin/app_kit
import darwin/objc/runtime
import darwin/foundation
import logging
import json

import ./events
export events
import ./logsetup
import ./baseapp
export baseapp

when defined(ios):
  {.passL: "-framework UIKit" .}
  {.passL: "-framework WebKit" .}
  {.emit: """
  #include <UIKit/UIKit.h>
  #include <WebKit/WebKit.h>
  """.}
elif defined(android):
  import jnim
  # import java/lang
  jclass org.wiish.wiishexample.WiishActivity of JVMObject:
    proc evalJavaScript(js: string)

type
  WebviewApp* = ref object of BaseApplication
    window*: WebviewWindow
  
  WebviewWindow* = ref object of BaseWindow
    onMessage*: EventSource[string]
    when defined(ios):
      wiishController*: pointer
    elif defined(android):
      wiishActivity*: WiishActivity

proc newWebviewApp(): WebviewApp =
  new(result)
  result.launched = newEventSource[bool]()
  result.willExit = newEventSource[bool]()
  new(result.window)
  result.window.onMessage = newEventSource[string]()

proc sendMessage*(win:WebviewWindow, message:string) =
  ## Send a message from Nim to JS
  when defined(ios):
    var
      controller = win.wiishController
      javascript:cstring = &"wiish._handleMessage({%message});"
    {.emit: """
    [controller evalJavaScript:[NSString stringWithUTF8String:javascript]];
    """.}
  elif defined(android):
    debug "Sending message to JS ..."
    debug "win: " & win.repr
    var
      activity = win.wiishActivity
      javascript = &"wiish._handleMessage({%message});"
    
    # {.emit: """
    # (*jenv)->ReleaseStringUTFChars(env, str, nativeString);
    # """.}
    activity.evalJavaScript(javascript)

template start*(app: WebviewApp, url: string) =
  ## Start the webview app at the given URL.

  when not compileOption("noMain"):
    {.error: "Please run Nim with --noMain flag.".}

  # Procs common to ios and android
  proc nimwin() : WebviewWindow {.exportc.} = app.window

  when defined(ios):
    proc jsbridgecode() : cstring {.exportc.} =
      """
      window.wiish = {};
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
      """

    proc doLog(x:cstring) {.exportc.} =
      debug(x)
    proc nim_didFinishLaunching() {.exportc.} =
      debug "didFinishLaunching"
      app.launched.emit(true)
    proc nim_applicationWillResignActive() {.exportc.} =
      debug "applicationWillResignActive"
    proc nim_applicationDidEnterBackground() {.exportc.} =
      debug "applicationDidEnterBackground"
    proc nim_applicationWillEnterForeground() {.exportc.} =
      debug "applicationWillEnterForeground"
    proc nim_applicationDidBecomeActive() {.exportc.} =
      debug "applicationDidBecomeActive"
    proc nim_applicationWillTerminate() {.exportc.} =
      debug "applicationWillTerminate"
    
    proc nim_gotMessage(x:cstring) {.exportc.} =
      app.window.onMessage.emit($x)
    
    proc getInitURL(): cstring {.exportc.} = url

    {.emit: """
    #include <UIKit/UIKit.h>
    #include <WebKit/WebKit.h>

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
      nim_gotMessage([message.body UTF8String]);
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
      self.view.backgroundColor = [UIColor greenColor];
      WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
      [theConfiguration.userContentController addScriptMessageHandler:self name:@"wiish"];
      [theConfiguration.userContentController addUserScript:userScript];

      webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:theConfiguration];
      webView.navigationDelegate = self;
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
    
  elif defined(android):
    import jnim
    proc nim_didFinishLaunching() {.exportc.} =
      debug "didFinishLaunching"
      app.launched.emit(true)
    
    # JNI helpers
    proc wiish_getInitURL(): cstring {.cdecl, exportc.} = url
    proc wiish_sendMessage(message:cstring) {.cdecl, exportc.} =
      ## message sent from js to nim
      app.window.onMessage.emit($message)

    # proc saveActivity(env: JNIEnvPtr, obj: jobject) {.exportc: "Java_org_wiish_exampleapp_WiishActivity_wiish_1init".} =
    proc saveActivity(obj: jobject) {.exportc.} =
      debug "Saving activity obj: " & obj.repr
      app.window.wiishActivity = WiishActivity.fromJObject(obj)
      debug "wiishActivity: " & app.window.repr

    {.emit: """
    #include <mainjni.h> // mainjni.h is generated from WiishActivity.java by a utility script
    N_CDECL(void, NimMain)(void);

    JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1init
  (JNIEnv * env, jobject obj) {
      NimMain();
      saveActivity(obj);
      nim_didFinishLaunching();
    }

    JNIEXPORT jstring JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1getInitURL
  (JNIEnv * env, jobject obj) {
      return (*env)->NewStringUTF(env, wiish_getInitURL());
    }

    JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1sendMessage
  (JNIEnv * env, jobject obj, jstring str) {
      const char *nativeString = (*env)->GetStringUTFChars(env, str, 0);
      wiish_sendMessage(nativeString);
      (*env)->ReleaseStringUTFChars(env, str, nativeString);
    }

    /*
    extern int cmdCount;
    extern char** cmdLine;
    extern char** gEnv;
    
    int main(int argc, char** args) {
      cmdLine = args;
      cmdCount = argc;
      gEnv = NULL;
      NimMain();
      return nim_program_result;
    }
    */
    """.}

    
  # app.willExit.emit(true)


var app* = newWebviewApp()
