## Hello, World Wiish App
import wiishpkg/webviewapp
import strformat
import strutils
import logging

info "Start"

app.launched.handle:
  debug "App launched"
  let index = app.resourcePath("index.html").replace(" ", "%20")
  debug &"index path: {index}"
  var w = app.newWindow(
    title = "Wiish Webview Demo",
    url = &"file://{index}")
  

app.willExit.handle:
  debug "App is exiting"

app.start()


