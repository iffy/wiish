import ./events
export events

type
  App = object
    ready*: EventSource[bool]

## The singleton application instance.
var app* = App()
app.ready = newEventSource[bool]()

when defined(macosx):
  when defined(ios):
    # iOS
    discard
  else:
    # macOS desktop
    proc mac_onReady {.exportc.} =
      app.ready.emit(true)
    
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
  mac_onReady();
}
- (void) applicationWillTerminate:(NSNotification *)aNotification {
  printf("Application will terminate\n");
}
@end

// Wiish
@interface Wiish: NSObject
{
  // MyWindow* window;
}
- (void)run;
@end
@implementation Wiish
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

    proc start*(app:App) =
      echo "Starting app"
      var wiish = newWiish()
      wiish.run()
