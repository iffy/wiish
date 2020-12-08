## Hello, World Wiish App
import wiish/plugins/webview/mobile
import strutils
import logging

import ./demo

var app = newWebviewMobileApp()

app.life.addListener proc(ev: MobileEvent) =
  case ev.kind
  of WindowAdded:
    var win = app.getWindow(ev.windowId)
    win.onReady.handle:
      attachSender(proc(msg: string) =
        win.sendMessage(msg)
      )
    win.onMessage.handle(msg):
      receiveMessage(msg)
  else:
    debug "Unhandled lifecycle message: ", $ev

let index_html = resourcePath("index.html").replace(" ", "%20")
app.start(url = "file://" & index_html)
