## Module for making Android Webview applications.
when not defined(android):
  {.fatal: "Only available for -d:android".}

import ./base
export base
import jnim

jclass org.wiish.wiishexample.WiishActivity of JVMObject:
  proc evalJavaScript*(js: string)
  proc getInternalStoragePath*(): string

type
  WebviewApp* = ref object of BaseApplication
    window*: AndroidWindow
  
  AndroidWindow* = ref object of WebviewWindow
    onReady*: EventSource[bool]
    onMessage*: EventSource[string]
    wiishActivity*: WiishActivity

proc newWebviewApp(): WebviewApp =
  new(result)
  result.launched = newEventSource[bool]()
  result.willExit = newEventSource[bool]()
  new(result.window)
  result.window.onMessage = newEventSource[string]()
  result.window.onReady = newEventSource[bool]()

proc evalJavaScript*(win:AndroidWindow, js:string) =
  ## Evaluate some JavaScript in the webview
  when defined(ios):
    var
      controller = win.wiishController
      javascript:cstring = js
    {.emit: """
    [controller evalJavaScript:[NSString stringWithUTF8String:javascript]];
    """.}
  elif defined(android):
    var
      activity = win.wiishActivity
      javascript = js
    activity.evalJavaScript(javascript)

proc sendMessage*(win:AndroidWindow, message:string) =
  ## Send a message from Nim to JS
  evalJavaScript(win, &"wiish._handleMessage({%message});")

#-----------------------------------------------------------
# main()
#-----------------------------------------------------------

template start*(app: WebviewApp, url: string) =
  ## Start the webview app at the given URL.

  when not compileOption("noMain"):
    {.error: "Please run Nim with --noMain flag.".}

  # Procs common to ios and android
  proc nimwin() : AndroidWindow {.exportc.} = app.window

  #--------------------------------------------------------
  # iOS
  #--------------------------------------------------------
  when defined(ios):
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
    
    proc nim_signalJSMessagesReady() {.exportc.} =
      debug "nim_signalJSMessagesReady"
      app.window.onReady.emit(true)
    proc nim_sendMessageToNim(x:cstring) {.exportc.} =
      debug "nim_sendMessageToNim: " & $x
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

  #--------------------------------------------------------
  # Android
  #--------------------------------------------------------
  elif defined(android):
    import jnim
    
    template withJNI(body:untyped):untyped =
      if theEnv.isNil():
        checkInit()
        body
      else:
        body

    # JNI helpers
    proc wiish_c_didFinishLaunching() {.exportc.} =
      withJNI:
        app.launched.emit(true)
    
    proc wiish_c_getInitURL(): cstring {.exportc.} =
      withJNI:
        result = url

    proc wiish_c_sendMessageToNim(message:cstring) {.exportc.} =
      ## message sent from js to nim
      withJNI:
        let msg = $message
        app.window.onMessage.emit(msg)

    proc wiish_c_signalJSIsReady() {.exportc.} =
      ## Child page is ready for messages
      withJNI:
        app.window.onReady.emit(true)

    proc wiish_c_saveActivity(obj: jobject) {.exportc.} =
      ## Store the activity where Nim can get to it for sending
      ## messages to JavaScript
      withJNI:
        app.window.wiishActivity = WiishActivity.fromJObject(obj)

    {.emit: """
    #include <org_wiish_exampleapp_WiishActivity.h> // This file is generated from WiishActivity.java by ./updateJNIheaders.sh
    N_CDECL(void, NimMain)(void);

    JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1init
  (JNIEnv * env, jobject obj) {
      NimMain();
      jobject gobj = (*env)->NewGlobalRef(env, obj);
      wiish_c_saveActivity(gobj);
      wiish_c_didFinishLaunching();
    }

    JNIEXPORT jstring JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1getInitURL
  (JNIEnv * env, jobject obj) {
      return (*env)->NewStringUTF(env, wiish_c_getInitURL());
    }

    JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1sendMessageToNim
  (JNIEnv * env, jobject obj, jstring str) {
      const char *nativeString = (*env)->GetStringUTFChars(env, str, 0);
      wiish_c_sendMessageToNim(nativeString);
      (*env)->ReleaseStringUTFChars(env, str, nativeString);
    }

    JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1signalJSIsReady
  (JNIEnv * env, jobject obj) {
      wiish_c_signalJSIsReady();
    }
    """.}



var app* = newWebviewApp()
