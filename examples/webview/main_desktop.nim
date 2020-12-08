## Hello, World Wiish App
import wiish/plugins/webview/desktop
import strformat
import strutils
import logging

import ./demo

var app = newWebviewDesktopApp()
let index = resourcePath("index.html").replace(" ", "%20")

app.life.addListener proc(ev: DesktopEvent) =
  case ev.kind
  of desktopAppStarted:
    var win = app.newWindow(
      title = "Wiish Webview Demo",
      url = &"file://{index}"
    )
    win.onReady.handle:
      attachSender(proc(msg: string) =
        win.sendMessage(msg)
      )
    win.onMessage.handle(msg):
      receiveMessage(msg)
  else:
    debug "Unhandled lifecycle message: ", $ev

app.start()
