## Hello, World Wiish App
import sdl2/sdl except log
import wiish/sdlapp
import logging
import opengl

import random
randomize()
var
  r = 45/255.0
  g = 52/255.0
  b = 54/255.0

app.launched.handle:
  # This is run as soon as the application is ready
  # to start making windows.
  debug "App launched"

  # Create a new window.
  var w = app.newGLWindow(title = "Hello, Wiish!")
  
  # Perform drawing for the window.
  w.onDraw.handle(rect):
    glClearColor(r, g, b, 0)
    glClear(GL_COLOR_BUFFER_BIT)

app.willExit.handle:
  # Run this code just before the application exits
  debug "App is exiting"

app.sdl_event.handle(evt):
  debug "Event"
  case evt.kind
  of MouseButtonDown:
    r = random(255).toFloat / 255.0
    g = random(255).toFloat / 255.0
    b = random(255).toFloat / 255.0
  else:
    discard

app.start()


