## Hello, World Wiish App
import wiishpkg/webview_mobile
import os
import strformat
import strutils
import logging
import times

let index_html = app.resourcePath("index.html").replace(" ", "%20")

app.launched.handle:
  debug "App launched"
  app.window.onReady.handle:
    app.window.sendMessage("Looks like you're ready, JS!")
  app.window.onMessage.handle(message):
    info "Got message from JavaScript: " & message
    app.window.sendMessage("Hello from Nim!")

app.willExit.handle:
  debug "App is exiting"

app.start(url = "file://" & index_html)

