import ../events
import ../wiishtypes

## List of created windows
var windows*:seq[Window]

## The singleton application instance.
var app* = App()
app.launched = newEventSource[bool]()
app.willExit = newEventSource[bool]()

proc didFinishLaunching {.exportc.} =
  app.launched.emit(true)

proc willTerminate {.exportc.} =
  app.willExit.emit(true)

proc drawWindow(w:Window) {.exportc.} =
  discard

proc viewWillStartLiveResize(w:Window) {.exportc.} =
  discard

proc viewDidEndLiveResize(w:Window) {.exportc.} =
  discard


{.passL: "-framework Foundation" .}
{.passL: "-framework AppKit" .}
{.passL: "-framework ApplicationServices" .}

{.emit: """
#include <Cocoa/Cocoa.h>
// WiishWindow
@interface WiishWindow : NSWindow {
  @public
  void* nimwindow;
}
@end
@implementation WiishWindow
- (BOOL) canBecomeKeyWindow {
    return YES;
}
- (BOOL) canBecomeMainWindow {
    return YES;
}
@end

// WiishView
// Based on https://github.com/yglukhov/nimx/blob/master/nimx/private/windows/appkit_window.nim
@interface WiishView : NSOpenGLView <NSTextInputClient> {
  @public
  void* nimwindow;
}
@end
@implementation WiishView
NSOpenGLPixelFormat* createPixelFormat(NSRect frame, int colorBits, int depthBits) {
   NSOpenGLPixelFormatAttribute pixelAttribs[ 16 ];
   int pixNum = 0;
   NSDictionary *fullScreenMode;

   pixelAttribs[pixNum++] = NSOpenGLPFADoubleBuffer;
   pixelAttribs[pixNum++] = NSOpenGLPFAAccelerated;
   pixelAttribs[pixNum++] = NSOpenGLPFAColorSize;
   pixelAttribs[pixNum++] = colorBits;
   pixelAttribs[pixNum++] = NSOpenGLPFADepthSize;
   pixelAttribs[pixNum++] = depthBits;
   pixelAttribs[pixNum] = 0;
   return [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelAttribs];
}
- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
       depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
    NSOpenGLPixelFormat *pixelFormat;

    pixelFormat = createPixelFormat(frame, numColorBits, numDepthBits);
    if( pixelFormat != nil )
    {
        self = [ super initWithFrame:frame pixelFormat:pixelFormat ];
        [ pixelFormat release ];
        if( self )
        {
            [ [ self openGLContext ] makeCurrentContext ];
            [ self reshape ];
        }
    }
    else
        self = nil;
    return self;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}
- (void)drawRect:(NSRect)r { drawWindow(nimwindow); }
- (void)viewWillStartLiveResize { viewWillStartLiveResize(nimwindow); }
- (void)viewDidEndLiveResize { viewDidEndLiveResize(nimwindow); }
- (void)keyDown: (NSEvent*) e {
    [super keyDown: e];
}
- (void)keyUp: (NSEvent*) e {
    [super keyUp: e];
}
- (void)insertText:(id)string replacementRange:(NSRange)replacementRange {
    NSLog(@"text: %@", string);
}
- (void)doCommandBySelector:(SEL)selector {

}
- (void)setMarkedText:(id)string selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange {

}
- (void)unmarkText {

}
- (NSRange)selectedRange {
    return NSMakeRange(0, 0);
}
- (NSRange)markedRange {
    return NSMakeRange(0, 0);
}
- (BOOL)hasMarkedText {
    return NO;
}
- (nullable NSAttributedString *)attributedSubstringForProposedRange:(NSRange)range actualRange:(nullable NSRangePointer)actualRange {
    return nil;
}
- (NSArray<NSString *> *)validAttributesForMarkedText {
    return nil;
}
- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(nullable NSRangePointer)actualRange {
    return NSZeroRect;
}
- (NSUInteger)characterIndexForPoint:(NSPoint)point {
    return -1;
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
  didFinishLaunching();
}
- (void) applicationWillTerminate:(NSNotification *)aNotification {
  willTerminate();
}
@end

// Wiish
@interface Wiish: NSObject {
}
- (void)terminateApp;
- (void)run;
@end
@implementation Wiish
- (void)terminateApp {
  [NSApp terminate:nil];
}
- (void)run {
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  [NSApplication sharedApplication];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  AppDelegate* appDel = [[AppDelegate alloc] init];
  [NSApp setDelegate: appDel];
  [NSApp run];
  [pool drain];
}
@end
""" .}

proc newWiish: Id {.importobjc: "Wiish new", nodecl .}
proc run(self: Id) {.importobjc: "run", nodecl .}
proc terminateApp(self: Id) {.importobjc: "terminateApp", nodecl .}

var wiish: Id

proc start*(app:App) =
  wiish = newWiish()
  wiish.run()

proc quit*(app:App) =
  wiish.terminateApp()

proc newWindow*():Window =
  var nimwindow {.exportc.} = Window()

  {.emit: """
  NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
  NSRect windowRect = NSMakeRect(100,100,400,300);
  WiishWindow* window = [[WiishWindow alloc] 
    initWithContentRect: windowRect
    styleMask: windowStyle
    backing: NSBackingStoreBuffered
    defer: YES];
  window->nimwindow = nimwindow;
  nimwindow->nativeWindow = window;
  WiishView* view = [[WiishView alloc] initWithFrame: [window frame]];
  if (view) {
    [view setWantsBestResolutionOpenGLSurface: YES];
    [window setContentView:view];
    [view release];
  }
  nimwindow->nativeView = view;
  [window setTitle: @"Hello, World!"];
  [window display];
  [window orderFrontRegardless];
  [window makeKeyWindow];
  """ .}

  windows.add(nimwindow)
  return nimwindow

# Handle pressing of control-C
proc onControlC() {.noconv.} =
  app.quit()
  quit(1)
setControlCHook(onControlC)
