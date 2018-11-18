## Hello, World Wiish App
import wiishpkg/webviewapp
import logging

app.launched.handle:
  debug "App launched"
  var w = app.newWindow(title = "Wiish Webview Demo", url = "https://www.google.com")

app.willExit.handle:
  debug "App is exiting"

app.start()


