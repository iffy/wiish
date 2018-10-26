import ./events
export events

type
  App = object
    launched*: EventSource[bool]
    willTerminate*: EventSource[bool]

## The singleton application instance.
var app* = App()
app.launched = newEventSource[bool]()
app.willTerminate = newEventSource[bool]()

when defined(macosx):
  when defined(ios):
    # iOS
    discard
  else:
    # macOS desktop
    proc mac_onLaunched {.exportc.} =
      app.launched.emit(true)
    
    proc mac_onWillTerminate {.exportc.} =
      app.willTerminate.emit(true)
    
    {.passL: "-framework Foundation" .}
    {.passL: "-framework AppKit" .}
    {.passL: "-framework ApplicationServices" .}
    
    {.emit: """
#include <Cocoa/Cocoa.h>
//// MyWindow
//
//@implementation MyWindow
//- (BOOL) canBecomeKeyWindow
//{
//    return YES;
//}
//- (BOOL) canBecomeMainWindow
//{
//    return YES;
//}
//@end

// AppDelegate
@interface AppDelegate : NSObject <NSApplicationDelegate>{}
@end
@implementation AppDelegate
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSNotification*) aNotification {
    return YES;
}
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
  printf("Application finished launching\n");
  mac_onLaunched();
}
- (void) applicationWillTerminate:(NSNotification *)aNotification {
  printf("Application will terminate\n");
  mac_onWillTerminate();
}
@end

// Wiish
@interface Wiish: NSObject
{
  // MyWindow* window;
}
- (void)terminateApp;
- (void)run;
@end
@implementation Wiish
- (void)terminateApp
{
  [NSApp terminate:nil];
}
- (void)run
{
  printf("init start\n");
  [NSApplication sharedApplication];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  //NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
  //NSRect windowRect = NSMakeRect(100,100,400,300);
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
}
@end
    """.}
    
    type
      Id {.importc: "id", header: "<objc/Object.h>", final.} = distinct int
    
    proc newWiish: Id {.importobjc: "Wiish new", nodecl .}
    proc run(self: Id) {.importobjc: "run", nodecl .}
    proc terminateApp(self: Id) {.importobjc: "terminateApp", nodecl .}
    
    var wiish: Id

    proc start*(app:App) =
      echo "Starting app"
      wiish = newWiish()
      wiish.run()
    
    proc quit*(app:App) =
      wiish.terminateApp()
