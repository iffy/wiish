## Hello, World Wiish App
import wiish/webview/mobile
import strutils
import logging
import memtools

var app = newWebviewMobileApp()

app.life.addListener proc(ev: MobileEvent) =
  info "Event: ", $ev
  case ev.kind
  of WindowAdded:
    var win = app.getWindow(ev.windowId)
    win.onReady.handle:
      debug "JS is ready"
      win.sendMessage("Nim knows the JS is ready")
    win.onMessage.handle(msg):
      debug "Got JS message: ", $msg
      win.sendMessage("Hello from Nim! You said " & msg)
  else:
    discard

let index_html = resourcePath("index.html").replace(" ", "%20")
debug $index_html
app.start(url = "file://" & index_html)
