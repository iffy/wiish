## Hello, World Wiish App
import wiish/webview/mobile
import strutils
import logging

var app = newWebviewMobileApp()

app.life.addListener proc(ev: MobileEvent) =
  case ev.kind
  of WindowAdded:
    debug "WindowAdded"
    var win = app.getWindow(ev.windowId)
    win.onReady.handle:
      debug "JS is ready"
      win.sendMessage("Nim knows the JS is ready")
    win.onMessage.handle(msg):
      debug "Got JS message: ", $msg
      win.sendMessage("Hello from Nim! You said " & msg)
  else:
    debug "Unhandled message: ", $ev

let index_html = resourcePath("index.html").replace(" ", "%20")
app.start(url = "file://" & index_html)
