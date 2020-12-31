#include <UIKit/UIKit.h>
#include <WebKit/WebKit.h>
#include <CoreFoundation/CoreFoundation.h>
#import "app.h"

// WiishWindowController
@interface WiishWindowController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler> {
  WKWebView* webView;
}
@property int windowID;
- (void)evalJavaScript:(NSString *)jscript;
@end

@implementation WiishWindowController { }
- (void)evalJavaScript:(NSString *)jscript {
  [webView evaluateJavaScript:jscript completionHandler:nil];
}
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name  isEqual: @"wiish_internal_ready"]) {
    nim_signalJSMessagesReady(self.windowID);
  } else {
    nim_sendMessageToNim(self.windowID, [message.body UTF8String]);
  }
}
- (void)viewDidLoad {
  [super viewDidLoad];
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

@interface WiishAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation WiishAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    WiishWindowController* ctrl = [WiishWindowController alloc];
    self.window.rootViewController = [ctrl init];
    self.window.backgroundColor = [UIColor redColor];
    [self.window makeKeyAndVisible];
    ctrl.windowID = nim_nextWindowId();
    nim_windowCreated(ctrl.windowID, (void*)CFBridgingRetain(ctrl)); // TODO: This isn't absolutely safe... but probably is :)
    nim_didFinishLaunching();
    return YES;
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    // TODO: when multiple scenes are supported, use a real windowId
    nim_windowWillBackground(0);
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    // TODO: when multiple scenes are supported, use a real windowId
    nim_windowWillForeground(0);
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    // TODO: when multiple scenes are supported, use a real windowId
    nim_windowDidForeground(0);
}
- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    nim_applicationWillTerminate();
}
@end

int startIOSLoop() {
  @autoreleasepool {
    return UIApplicationMain(0, nil, nil, NSStringFromClass([WiishAppDelegate class]));
  }
}
