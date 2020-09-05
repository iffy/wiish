#include <UIKit/UIKit.h>
#include <WebKit/WebKit.h>
#include <CoreFoundation/CoreFoundation.h>
#import "webview_ios.h"

// WiishController
@interface WiishController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler> {
  WKWebView* webView;
}
- (void)evalJavaScript:(NSString *)jscript;
@end

@implementation WiishController { }
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
  // TODO: This isn't absolutely safe... but probably is :)
  registerWiishController((void*)self);

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
    self.window.rootViewController = [[WiishController alloc] init];
    self.window.backgroundColor = [UIColor redColor];
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

int startIOSLoop() {
  @autoreleasepool {
    return UIApplicationMain(0, nil, nil, NSStringFromClass([WiishAppDelegate class]));
  }
}
