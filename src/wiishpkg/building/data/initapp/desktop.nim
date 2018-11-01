## Hello, World Wiish App
import wiishpkg/main
import opengl

app.launched.handle:
  # This is run as soon as the application is ready
  # to start making windows.

  # Create a new window.
  var w = newWindow(title = "Hello, Wiish!")
  
  # Perform drawing for the window.
  w.onDraw.handle(rect):
    glClearColor(0.5, 0.5, 0.75, 0)
    glClear(GL_COLOR_BUFFER_BIT)

app.willExit.handle:
  # Run this code just before the application exits
  echo "App is exiting"

app.start()


