## Hello, World Wiish App
import wiishpkg/main

app.launched.handle:
  echo "App launched"

app.willExit.handle:
  echo "App is exiting"

app.start()


