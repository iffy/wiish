## Hello, World Wiish App
import wiishpkg/webview_mobile
import strformat
import strutils
import logging

info "Start"

let index = app.resourcePath("index.html").replace(" ", "%20")
# debug &"index path: {index}"
app.url = "file://" & index

app.launched.handle:
  debug "App launched"

app.willExit.handle:
  debug "App is exiting"

app.start()


