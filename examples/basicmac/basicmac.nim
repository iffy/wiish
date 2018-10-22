## Bare-bones MacOS application

when defined(macosx):
  when defined(ios):
    # iOS
    echo "ios"
  else:
    # desktop macOS
    {.passL: "-framework Cocoa"}
    {.passL: "-framework Foundation" .}
    {.passL: "-framework AppKit" .}
    {.passL: "-framework ApplicationServices" .}
    {.emit: "#import <Cocoa/Cocoa.h>" .}

    {.emit: """
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
    """.}

    {.emit: """
    @interface AppDelegate : NSObject <NSApplicationDelegate>{}
    @end

    @implementation AppDelegate
    - (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSNotification*) aNotification {
      return YES;
    }
    @end
    """.}
    proc displayWindow() =
      echo "displaying window"
      {.emit: """
      @autoreleasepool
      {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
        NSRect windowRect = NSMakeRect(100,100,400,300);
        MyWindow* window = [[MyWindow alloc] 
          initWithContentRect: windowRect
          styleMask: windowStyle
          backing: NSBackingStoreBuffered
          defer: YES];
        
        [window setTitle: @"Hello, World!"];
        [window display];
        //[window orderFrontRegardless];
        [window makeKeyWindow];
        AppDelegate* appDel = [[AppDelegate alloc] init];
        [NSApp setDelegate: appDel];
        [NSApp run];
      }
      """.}
      echo "end of displaying window"


if isMainModule:
  displayWindow()