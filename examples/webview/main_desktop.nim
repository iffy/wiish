## Hello, World Wiish App
import wiish/webview/desktop
import strformat
import strutils
import logging

var app = newWebviewDesktopApp()
let index = resourcePath("index.html").replace(" ", "%20")

app.life.addListener proc(ev: DesktopEvent) =
  case ev.kind
  of desktopAppStarted:
    debug "App launched"
    let window = app.newWindow(
      title = "Wiish Webview Demo",
      url = &"file://{index}"
    )
    window.onMessage.handle(message):
      info "app: onMessage: " & message
      window.sendMessage("Hello from Nim! " & message)
    window.onReady.handle:
      info "app: onReady"
  of desktopAppWillExit:
    debug "App about to exit"

app.start()
