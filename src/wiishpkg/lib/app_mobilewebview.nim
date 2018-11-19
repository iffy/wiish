## Mobile Webview Application
import macros
import times
import logging

import ./app_common
export app_common
import ../events

type
  WebviewApp* = ref object of BaseApplication
    windows*: seq[WebviewWindow]
  
  WebviewWindow* = ref object of BaseWindow

proc createApplication*(): WebviewApp =
  new(result)
  result.launched = newEventSource[bool]()
  result.willExit = newEventSource[bool]()

proc newWindow*(app: WebviewApp, url:string = ""): WebviewWindow =
  new(result)
  app.windows.add(result)
  when defined(ios):
    discard
  elif defined(android):
    warn "Android not yet supported"

template start*(app: WebviewApp) =
  when defined(ios):
    proc nim_didFinishLaunching() {.exportc.} =
      debug "didFinishLaunching"
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

    {.passL: "-framework UIKit" .}
    {.passL: "-framework WebKit" .}
    {.emit: """
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// Our iOS view controller
@interface ViewController : UIViewController
  // WKWebView webview;
@end
@implementation ViewController {
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view = [[UIView alloc] initWithFrame:self.view.frame];
    self.view.backgroundColor = [UIColor greenColor];
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:theConfiguration];
    webView.navigationDelegate = self;
    NSURL *nsurl=[NSURL URLWithString:@"http://www.apple.com"];
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
    [webView loadRequest:nsrequest];
    [self.view addSubview:webView];
    return;
}
@end

// class ViewController: UIViewController, WKUIDelegate {
//     
//     var webView: WKWebView!
//     
//     override func loadView() {
//         let webConfiguration = WKWebViewConfiguration()
//         webView = WKWebView(frame: .zero, configuration: webConfiguration)
//         webView.uiDelegate = self
//         view = webView
//     }
//     override func viewDidLoad() {
//         super.viewDidLoad()
//         
//         let myURL = URL(string:"https://www.apple.com")
//         let myRequest = URLRequest(url: myURL!)
//         webView.load(myRequest)
//     }}

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[ViewController alloc] init];
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
        // argc == 1
        // argv[1] == executable being executed
        NSLog(@"Hello from main");
        NimMain();
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

  """.}
  elif defined(android):
    discard
  # app.willExit.emit(true)

proc quit*(app: WebviewApp) =
  warn "quit NOT IMPLEMENTED"