#include <Cocoa/Cocoa.h>
// MyWindow
@interface MyWindow: NSWindow
- (BOOL) canBecomeKeyWindow;
- (BOOL) canBecomeMainWindow;
@end

// AppDelegate
@interface AppDelegate : NSObject <NSApplicationDelegate>{}
@end

// Wiish
@interface Wiish: NSObject
{
  MyWindow* window;
}
- (void)run;
- (id)windowID;
@end
