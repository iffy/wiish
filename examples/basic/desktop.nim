## Bare-bones application
import wiishpkg/main
import opengl
import random

randomize()

app.launched.handle:
  echo "app code: app.launched"
  var w = newWindow("Some Title")
  w.onDraw.handle(rect):
    glClearColor(rand(1.0), rand(1.0), rand(1.0), 0)
    glClear(GL_COLOR_BUFFER_BIT)

  var w2 = newWindow("Another")
  w2.onDraw.handle(rect):
    glClearColor(rand(1.0), rand(1.0), rand(1.0), 0)
    glClear(GL_COLOR_BUFFER_BIT)

app.willExit.handle:
  echo "application code: app.willExit"

app.start()


