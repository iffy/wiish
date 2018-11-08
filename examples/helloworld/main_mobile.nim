## Hello, World Wiish App
import opengl
import math
import wiishpkg/main

app.launched.handle:
  log "App launched"
  var w = newWindow()
  w.onDraw.handle(rect):
    glClearColor(45/255.0, 52/255.0, 54/255.0, 0)
    glClear(GL_COLOR_BUFFER_BIT)

app.willExit.handle:
  log "App exiting"

app.start()


