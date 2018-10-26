import sequtils
import ./events
import ./logging
import glfw
import os
export events

type
  App = object
    launched*: EventSource[bool]
    willExit*: EventSource[bool]
  Window* = ref object
    willExit*: EventSource[bool]
    glfwWindow: glfw.Window

var windows:seq[Window]

proc newWindow*():Window =
  log "newWindow()"
  result = Window()
  result.willExit = newEventSource[bool]()
  windows.add(result)

  var c = DefaultOpenglWindowConfig
  c.title = "Some title"
  result.glfwWindow = glfw.newWindow(c)

proc close*(win: var Window) =
  log "window.close()"
  windows.del(windows.find(win))
  win.willExit.emit(true)
  win.glfwWindow.destroy()


## The singleton application instance.
var app* = App()
app.launched = newEventSource[bool]()
app.willExit = newEventSource[bool]()

proc start*(app:App)
proc quit*(app:App)

proc mainloop(app:App) =
  log "mainloop()"
  var therehavebeenwindows = false
  while not(therehavebeenwindows) or (therehavebeenwindows and windows.len > 0):
    if not therehavebeenwindows and windows.len > 0:
      therehavebeenwindows = true
    var old_windows = windows # make a copy so that they can be removed from the seq within the loop
    for window in old_windows:
      var w = window
      if w.glfwWindow.shouldClose:
        w.close()
      else:
        if w.glfwWindow.isKeyDown(keyEscape):
          log "Escape key is down"
          w.glfwWindow.shouldClose = true
        w.glfwWindow.swapBuffers()
    pollEvents()
  log "mainloop finished, quitting now"
  app.willExit.emit(true)
  app.quit()

proc start*(app:App) =
  log "app.start()"
  glfw.initialize()
  app.launched.emit(true)
  app.mainloop()

proc quit*(app:App) =
  log "app.quit()"
  app.willExit.emit(true)
  for w in windows:
    var w = w
    w.close()
  glfw.terminate()

# Handle pressing of control-C
proc onControlC() {.noconv.} =
  log "onControlC()"
  app.quit()
  quit(1)
setControlCHook(onControlC)