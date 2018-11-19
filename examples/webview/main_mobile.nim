## Hello, World Wiish App
import wiishpkg/mobilewebviewapp
import strformat
import strutils
import logging

info "Start"

app.launched.handle:
  debug "App launched"
  let index = app.resourcePath("index.html").replace(" ", "%20")
  debug &"index path: {index}"
  var w = app.newWindow(
    url = &"file://{index}")
  

app.willExit.handle:
  debug "App is exiting"

app.start()


