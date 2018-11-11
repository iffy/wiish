## Bare-bones application
import wiishpkg/desktop
import opengl
import random

randomize()

app.launched.handle:
  log "app code: app.launched"
  var w = app.newGLWindow("Some Title")
  w.onDraw.handle(rect):
    glClearColor(rand(1.0), rand(1.0), rand(1.0), 0)
    glClear(GL_COLOR_BUFFER_BIT)

  var w2 = app.newGLWindow("Another")
  w2.onDraw.handle(rect):
    glClearColor(rand(1.0), rand(1.0), rand(1.0), 0)
    glClear(GL_COLOR_BUFFER_BIT)

app.willExit.handle:
  log "application code: app.willExit"

app.start()


