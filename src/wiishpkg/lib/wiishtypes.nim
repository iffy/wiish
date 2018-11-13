import sdl2/sdl
import opengl
import ../events
import ../defs

type
  Rectangle* = tuple[x, y, width, height: float32]
  
  Application* = ref object of RootRef
    launched*: EventSource[bool]
    willExit*: EventSource[bool]
    windows*: seq[Window]
    # A stream of SDL events
    sdl_event*: EventSource[ptr sdl.Event]
  
  Window* = ref object of RootRef
    # events
    onDraw*: EventSource[Rectangle]
    # attributes/properties
    sdlWindow*: sdl.Window
    sdlGlContext*: sdl.GLContext
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

proc newRectangle*(x, y, width, height: float32 = 0):Rectangle =
  result = (x, y, width, height)

template newRectangle*(x, y, width, height: int32 = 0):Rectangle =
  newRectangle(x.toFloat, y.toFloat, width.toFloat, height.toFloat)

proc createApplication*(): Application =
  new(result)
  result.launched = newEventSource[bool]()
  result.willExit = newEventSource[bool]()
  result.sdl_event = newEventSource[ptr sdl.Event]()

