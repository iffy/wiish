import sdl2
import opengl
import ../events
import ../defs

type
  Rect* = tuple[x, y, width, height: float32]
  BaseApp = ref object of RootRef
    launched*: EventSource[bool]
    willExit*: EventSource[bool]
    event*: EventSource[Event]
  
  BaseWindow = ref object of RootRef
    # events
    onDraw*: EventSource[Rect]
    # attributes/properties
    frame*: Rect
  
  EventKind* = enum
    Unknown,
    FingerDown,
    FingerUp,
    MouseMotion,
    MouseButtonUp,
    MouseButtonDown,
  
  Event* = ref object of RootRef
    kind*: EventKind

proc newRect*(x, y, width, height: float32 = 0):Rect =
  result = (x, y, width, height)

template newRect*(x, y, width, height: int32 = 0):Rect =
  newRect(x.toFloat, y.toFloat, width.toFloat, height.toFloat)

type
  App* = ref object of BaseApp
    windows*: seq[Window]
  Window* = ref object of BaseWindow
    sdlWindow*: sdl2.WindowPtr
    sdlGlContext*: sdl2.GlContextPtr

## The singleton application instance.
var app* = App()
app.launched = newEventSource[bool]()
app.willExit = newEventSource[bool]()
app.event = newEventSource[Event]()
