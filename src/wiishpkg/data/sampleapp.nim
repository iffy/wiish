## Hello, World Wiish App
import wiishpkg/main

var w:Window

app.launched.handle:
  w = newWindow()
  w.willExit.handle:
    echo "Window is closing"

app.willExit.handle:
  echo "App is exiting"

app.start()


