## Hello, World Wiish App
import wiish/webview/mobile
# # import os
# # import strformat
import strutils
import logging
# # import times

var app = newWebviewMobileApp()

app.life.addListener proc(ev: MobileEvent) =
  info "Event: ", $ev
  case ev.kind
  of WindowAdded:
    echo "window ", $ev.windowId, " added"
    let win = app.getWindow(ev.windowId)
    win.onReady.handle:
      info "JS is ready"
    win.onMessage.handle(msg):
      info "Got JS message: ", $msg
      win.sendMessage("Hello from Nim! You said " & msg)
  else:
    discard

let index_html = resourcePath("index.html").replace(" ", "%20")
debug $index_html
app.start(url = "file://" & index_html)

# # app.launched.handle:
# #   debug "app: App launched"
# #   app.window.onReady.handle:
# #     info "app: onReady"
# #     app.window.sendMessage("Looks like you're ready, JS!")
# #   app.window.onMessage.handle(message):
# #     info "app: onMessage: " & message
# #     app.window.sendMessage("Hello from Nim! " & message)

# # app.willExit.handle:
# #   debug "app: App is exiting"

# # app.start(url = "file://" & index_html)
