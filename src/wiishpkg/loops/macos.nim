import opengl
import darwin/app_kit
import ../events
import ../wiishtypes
import ../logging
import ../context

#------------------------------------------------
# Headers
#------------------------------------------------

#------------------------------------------------
# To add to darwin package
import darwin/objc/runtime
proc frame*(v: NSWindow): NSRect {.objc: "frame".}
#------------------------------------------------

## List of created windows
var windows*:seq[Window]

## The singleton application instance.
var app* = App()
app.launched = newEventSource[bool]()
app.willExit = newEventSource[bool]()

#------------------------------------------------
# Convert nim objects to NS objects
#------------------------------------------------
template nativeView(win:Window): NSView =
  cast[NSView](win.nativeViewPtr)

template nativeWindow(win:Window): NSWindow =
  cast[NSWindow](win.nativeWindowPtr)

#------------------------------------------------
# Procs for objective C to call
#------------------------------------------------
proc didFinishLaunching {.exportc.} =
  app.launched.emit(true)

proc willTerminate {.exportc.} =
  app.willExit.emit(true)

proc drawWindow(w:Window) {.exportc.} =
  if w.context.isNil:
    return

  let viewFrame = newRect(
    x = w.nativeWindow.frame.origin.x,
    y = w.nativeWindow.frame.origin.y,
    width = w.nativeView.frame.size.width,
    height = w.nativeView.frame.size.height,
  )
  w.onDraw.emit(viewFrame)

  {.emit: """
  [[w->nativeViewPtr openGLContext] flushBuffer];
  """.}

proc viewWillStartLiveResize(w:Window) {.exportc.} =
  log "viewWillStartLiveResize"

proc viewDidEndLiveResize(w:Window) {.exportc.} =
  log "viewDidEndLiveResize"


# {.passL: "-framework Foundation" .}
{.passL: "-framework AppKit" .}
{.passL: "-framework OpenGL" .}
# {.passL: "-framework ApplicationServices" .}

{.emit: """
#include <OpenGL/gl.h>
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
  WiishWindow* window;
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
- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen {
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
- (void) prepareOpenGL {
    glClearColor(0.9, 0.9, 0.9, 1);
    glClear(GL_COLOR_BUFFER_BIT);
}
- (BOOL)acceptsFirstResponder {
    return YES;
}
- (void)drawRect:(NSRect)r {
  drawWindow(window->nimwindow);
}
- (void)viewWillStartLiveResize { viewWillStartLiveResize(window->nimwindow); }
- (void)viewDidEndLiveResize { viewDidEndLiveResize(window->nimwindow); }
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

proc setGLContext*(window: Window) =
  {.emit: """
  [ [window->nativeViewPtr openGLContext ] makeCurrentContext ];
  """.}
  
proc newWindow*(title:string = ""): Window =
  var nwin {.exportc.} = Window()
  nwin.onDraw = newEventSource[wiishtypes.Rect]()

  nwin.frame = newRect(200, 300, 400, 400)
  var
    x, y, width, height {.exportc.} : float32
    window_title {.exportc.}: NSString
  x = nwin.frame.x
  y = nwin.frame.y
  width = nwin.frame.width
  height = nwin.frame.height
  window_title = title

  {.emit: """
  NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
  NSRect windowRect = NSMakeRect(100,100,400,300);
  windowRect.size.width = width;
  windowRect.size.height = height;
  windowRect.origin.x = x;
  windowRect.origin.y = y;
  WiishWindow* window = [[WiishWindow alloc] 
    initWithContentRect: windowRect
    styleMask: windowStyle
    backing: NSBackingStoreBuffered
    defer: YES];
  window->nimwindow = nwin;
  nwin->nativeWindowPtr = window;
  WiishView* view = [[WiishView alloc]
    initWithFrame: [window frame]
    colorBits: 16
    depthBits: 16
    fullscreen: FALSE];
  if (view) {
    view->window = window;
    nwin->nativeViewPtr = view;
    [view setWantsBestResolutionOpenGLSurface: YES];
    [window setContentView:view];
    [view release];
  }
  [window setTitle: window_title];
  [window display];
  [window orderFrontRegardless];
  [window makeKeyWindow];
  """ .}
  nwin.context = newGLContext()
  #nwin.setGLContext()
  {.emit: """
  [window makeKeyAndOrderFront:nil];
  """.}
  windows.add(nwin)
  return nwin

# Handle pressing of control-C
proc onControlC() {.noconv.} =
  app.quit()
  quit(1)
setControlCHook(onControlC)
