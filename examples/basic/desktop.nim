## Bare-bones application
import wiishpkg/main

var w:Window

app.launched.handle:
  echo "app code: app.launched"
  w = newWindow()
  echo "app code: window ", w.repr
  w.willExit.handle:
    echo "app code: window.willExit"
  
  w.onDraw.handle(rect):
    echo "app draw: ", rect

app.willExit.handle:
  echo "application code: app.willExit"

app.start()


