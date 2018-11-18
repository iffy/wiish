## Hello, World Wiish App
import wiishpkg/webviewapp
import logging

app.launched.handle:
  debug "App launched"
  # var w = app.newWebviewWindow(title = "Wiish Webview Demo")

app.willExit.handle:
  debug "App is exiting"

app.start()


