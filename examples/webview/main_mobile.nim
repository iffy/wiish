## Hello, World Wiish App
import wiish/webview/mobile
# import os
# import strformat
import strutils
import logging
# import times

var app = newWebviewMobileApp()

let index_html = resourcePath("index.html").replace(" ", "%20")
echo $index_html

app.life.onCreate.handle:
  debug "onCreate"

app.life.onStart.handle:
  debug "App launched"

app.life.onResume.handle:
  debug "onResume"

app.life.onPause.handle:
  debug "onPause"

app.life.onStop.handle:
  debug "onStop"

app.life.onDestroy.handle:
  debug "onDestroy"

app.start(url = "file://" & index_html)

# app.launched.handle:
#   debug "app: App launched"
#   app.window.onReady.handle:
#     info "app: onReady"
#     app.window.sendMessage("Looks like you're ready, JS!")
#   app.window.onMessage.handle(message):
#     info "app: onMessage: " & message
#     app.window.sendMessage("Hello from Nim! " & message)

# app.willExit.handle:
#   debug "app: App is exiting"

# app.start(url = "file://" & index_html)
