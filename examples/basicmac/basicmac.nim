## Bare-bones application
import wiishpkg/application
import strutils
import glfw
import os

var w:glfw.Window

app.launched.handle(message):
  echo "application launched"
  glfw.initialize()
  echo "glfw initializes"
  var c = DefaultOpenglWindowConfig
  c.title = "Running GLFW in a Mac App"
  echo "making new window"
  w = newWindow(c)
  echo "made new window"

app.willTerminate.handle(message):
  echo "application willTerminate"

app.start()


