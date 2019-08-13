## Hello, World Wiish App
import wiishpkg/webview_mobile
import os
import strformat
import strutils
import logging
import times

let index_html = app.resourcePath("index.html").replace(" ", "%20")

debug "main_mobile"
# debug "main_mobile thread id: " & $getThreadId()

app.launched.handle:
  debug "App launched"
  # debug "thread id: " & $getThreadId()
  app.window.onReady.handle:
    info "onReady"
    app.window.sendMessage("Looks like you're ready, JS!")
  app.window.onMessage.handle(message):
    info "onMessage: " & message
    app.window.sendMessage("Hello from Nim!")

app.willExit.handle:
  debug "App is exiting"

app.start(url = "file://" & index_html)


# debug "main_mobile thread id: " & $getThreadId()