import ./events

type
  BaseApp = ref object of RootRef
    launched*: EventSource[bool]
    willExit*: EventSource[bool]
  BaseWindow = ref object of RootRef
    willExit*: EventSource[bool]

when defined(macosx) and not defined(ios):
  type
    Id* {.importc: "id", header: "<objc/Object.h>", final .} = distinct int
  type
    App* = ref object of BaseApp
    Window* = ref object of BaseWindow
      nativeWindow: pointer # WiishWindow
      nativeView: pointer # WiishView
else:
  import glfw
  type
    App* = ref object of BaseApp
    Window* = ref object of BaseWindow
      glfwWindow*: glfw.Window
      