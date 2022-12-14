## Hello, World, OpenGL Wiish App.
## Click with the mouse to make the color change.
import wiish/plugins/sdl2/desktop
import logging
import sdl2
import opengl

import std/random
randomize()
var
  r = 45/255.0
  g = 52/255.0
  b = 54/255.0

var app = newSDL2DesktopApp()

app.life.addListener proc(ev: LifeEvent) =
  case ev.kind
  of AppStarted:
    debug "App launched"
    var w = app.newGLWindow(title = "Hello, Wiish!")
    w.draw = proc(rect: Rectangle) =
      glClearColor(r, g, b, 0)
      glClear(GL_COLOR_BUFFER_BIT)

  of AppWillExit:
    # Run this code just before the application exits
    debug "App is exiting"
  else:
    discard

app.sdl_event.handle(evt):
  debug "Event"
  case evt.kind
  of MouseButtonDown:
    # click to randomly change the color
    r = rand(255).toFloat / 255.0
    g = rand(255).toFloat / 255.0
    b = rand(255).toFloat / 255.0
  else:
    discard

app.start()
