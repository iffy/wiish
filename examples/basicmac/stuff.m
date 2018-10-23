#include <Cocoa/Cocoa.h>
#include <stdio.h>
#include <stdlib.h>

// @interface MyWindow: NSWindow
// - (BOOL) canBecomeKeyWindow;
// - (BOOL) canBecomeMainWindow;
// @end
// @implementation MyWindow
// - (BOOL) canBecomeKeyWindow
// {
//     return YES;
// }
// - (BOOL) canBecomeMainWindow
// {
//     return YES;
// }
// @end

// @interface AppDelegate : NSObject <NSApplicationDelegate>{}
// @end
// @implementation AppDelegate
// - (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSNotification*) aNotification {
//     return YES;
// }
// @end

@interface MyStuff: NSObject
{
}
- (void)dostuff: (int)x;
@end

@implementation MyStuff
- (void)dostuff: (int)x
{
    printf("Hello from objective C!\n");
}
@end
