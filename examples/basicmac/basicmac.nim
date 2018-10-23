## Bare-bones MacOS application
# import strutils
# import sdl2
# import sdl2/gfx
# import system
# discard sdl2.init(INIT_EVERYTHING)

when defined(macosx):
  when defined(ios):
    # iOS
    echo "ios"
  else:
    # desktop macOS
    proc someNimFunc {.exportc.} =
      echo "some nim func"
    
    {.passL: "-framework Foundation" .}
    {.passL: "-framework AppKit" .}
    {.passL: "-framework ApplicationServices" .}
    {.emit: """
#include <Cocoa/Cocoa.h>
// MyWindow
@interface MyWindow: NSWindow
- (BOOL) canBecomeKeyWindow;
- (BOOL) canBecomeMainWindow;
@end
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
@interface AppDelegate : NSObject <NSApplicationDelegate>{}
@end
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
@interface Wiish: NSObject
{
  MyWindow* window;
}
- (void)run;
- (id)windowID;
@end

@implementation Wiish
- (void)run
{
  printf("init start\n");
  [NSApplication sharedApplication];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
  NSRect windowRect = NSMakeRect(100,100,400,300);
  //window = [[MyWindow alloc] 
  //  initWithContentRect: windowRect
  //  styleMask: windowStyle
  //  backing: NSBackingStoreBuffered
  //  defer: YES];
  //[window setTitle: @"Hello, World!"];
  //[window display];
  //[window orderFrontRegardless];
  //[window makeKeyWindow];
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
    """ .}
    
    type
      Id {.importc: "id", header: "<objc/Object.h>", final.} = distinct int
    
    proc newWiish: Id {.importobjc: "Wiish new", nodecl .}
    proc run(self: Id) {.importobjc: "run", nodecl .}
    proc windowID(self: Id):Id {.importobjc: "windowID", nodecl .}

    proc displayWindow() =
      var stuff:Id
      echo "displaying window"
      stuff = newWiish()
      stuff.run
      echo "after displaying window"

if isMainModule:
  displayWindow()