import sdl2
import opengl
import ../events
import ../defs

type
  Rect* = tuple[x, y, width, height: float32]
  
  Application* = ref object of RootRef
    launched*: EventSource[bool]
    willExit*: EventSource[bool]
    windows*: seq[Window]
    # A stream of SDL events
    sdl_event*: EventSource[ptr sdl2.Event]
  
  Window* = ref object of RootRef
    # events
    onDraw*: EventSource[Rect]
    # attributes/properties
    sdlWindow*: sdl2.WindowPtr
    sdlGlContext*: sdl2.GlContextPtr
    frame*: Rect
  
  # EventKind* = enum
  #   Unknown,
  #   FingerDown,
  #   FingerUp,
  #   MouseMotion,
  #   MouseButtonUp,
  #   MouseButtonDown,
  
  # Event* = ref object of RootRef
  #   kind*: EventKind

proc newRect*(x, y, width, height: float32 = 0):Rect =
  result = (x, y, width, height)

template newRect*(x, y, width, height: int32 = 0):Rect =
  newRect(x.toFloat, y.toFloat, width.toFloat, height.toFloat)

proc createApplication*(): Application =
  new(result)
  result.launched = newEventSource[bool]()
  result.willExit = newEventSource[bool]()
  result.sdl_event = newEventSource[ptr sdl2.Event]()

