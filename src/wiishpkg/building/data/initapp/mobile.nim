## Hello, World Wiish App
import wiishpkg/main

app.launched.handle:
  var w = newWindow()
  w.willExit.handle:
    echo "Window is closing"

app.willExit.handle:
  echo "App is exiting"

app.start()


