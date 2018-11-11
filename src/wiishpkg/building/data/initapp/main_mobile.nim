## Hello, World Wiish App
import sdl2
import opengl
import math
import wiishpkg/mobile

import random
randomize()
var
  r = 45/255.0
  g = 52/255.0
  b = 54/255.0

app.launched.handle:
  log "App launched"
  var w = app.newGLWindow()
  w.onDraw.handle(rect):
    glClearColor(r, g, b, 0)
    glClear(GL_COLOR_BUFFER_BIT)

app.willExit.handle:
  log "App exiting"

app.sdl_event.handle(evt):
  log "Event"
  case evt.kind
  of FingerDown:
    r = random(255).toFloat / 255.0
    g = random(255).toFloat / 255.0
    b = random(255).toFloat / 255.0
  else:
    discard

app.start()


