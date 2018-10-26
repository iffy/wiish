## Bare-bones application
import wiishpkg/main

var w:Window

app.launched.handle:
  echo "app code: app.launched"
  w = newWindow()
  w.willExit.handle:
    echo "app code: window.willExit"

app.willExit.handle:
  echo "application code: app.willExit"

app.start()


