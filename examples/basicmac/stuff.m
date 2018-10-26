#include <Cocoa/Cocoa.h>
#include <stuff.h>
// MyWindow

@implementation MyWindow
- (BOOL) canBecomeKeyWindow
{
    return YES;
}
- (BOOL) canBecomeMainWindow
{
    return YES;
}
@end

// AppDelegate
@implementation AppDelegate
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSNotification*) aNotification {
    return YES;
}
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
  printf("Application finished launching\n");
  someNimFunc();
}
- (void) applicationWillTerminate:(NSNotification *)aNotification {
  printf("Application will terminate\n");
}
@end

// Wiish
@implementation Wiish
- (void)run
{
  printf("init start\n");
  [NSApplication sharedApplication];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
  NSRect windowRect = NSMakeRect(100,100,400,300);
  window = [[MyWindow alloc] 
    initWithContentRect: windowRect
    styleMask: windowStyle
    backing: NSBackingStoreBuffered
    defer: YES];
  [window setTitle: @"Hello, World!"];
  [window display];
  [window orderFrontRegardless];
  [window makeKeyWindow];
  AppDelegate* appDel = [[AppDelegate alloc] init];
  [NSApp setDelegate: appDel];
  [NSApp run];
  printf("init end\n");
}
- (id)windowID
{
  return window;
}
@end