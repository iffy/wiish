import glfw
import opengl
import ../logging
import ../wiishtypes
import ../../events

## List of created windows
var windows*:seq[wiishtypes.Window]

proc newWindow*(title:string = ""): wiishtypes.Window =
  new(result)
  windows.add(result)

  var c = DefaultOpenglWindowConfig
  c.title = title
  result.glfwWindow = newWindow(c)

proc close*(win: var wiishtypes.Window) =
  windows.del(windows.find(win))
  win.glfwWindow.destroy()


proc mainloop(app:App) =
  loadExtensions()
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
          w.glfwWindow.shouldClose = true
        let dims = w.glfwWindow.size
        w.glfwWindow.makeContextCurrent()
        w.onDraw.emit(newRect(
          x = 0,
          y = 0,
          width = dims.w,
          height = dims.h,
        ))
        w.glfwWindow.swapBuffers()
    waitEvents()
  app.willExit.emit(true)
  app.quit()

proc start*(app:App) =
  glfw.initialize()
  app.launched.emit(true)
  app.mainloop()

proc quit*(app:App) =
  app.willExit.emit(true)
  for w in windows:
    var w = w
    w.close()
  glfw.terminate()

# Handle pressing of control-C
proc onControlC() {.noconv.} =
  app.quit()
  quit(1)
setControlCHook(onControlC)
