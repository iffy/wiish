## Hello, World Wiish App
import wiish/webview/desktop
import strformat
import strutils
import logging

let index = app.resourcePath("index.html").replace(" ", "%20")

app.launched.handle:
  debug "app: App launched"
  let window = app.newWindow(
    title = "Wiish Webview Demo",
    url = &"file://{index}"
  )
  window.onMessage.handle(message):
    info "app: onMessage: " & message
    window.sendMessage("Hello from Nim! " & message)
  window.onReady.handle:
    info "app: onReady"
  

app.willExit.handle:
  debug "app: App is exiting"

app.start()


