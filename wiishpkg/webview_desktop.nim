## Module for making desktop Webview applications.
import webview
import macros
import times
import logging

import ./events
export events
import ./logsetup
import ./baseapp
export baseapp

type
  WebviewApp* = ref object of BaseApplication
    windows*: seq[WebviewWindow]
  
  WebviewWindow* = ref object of BaseWindow
    webview*: Webview

proc newWebviewApp(): WebviewApp =
  new(result)
  result.launched = newEventSource[bool]()
  result.willExit = newEventSource[bool]()

proc newWindow*(app: WebviewApp, title:string = "", url:string = ""): WebviewWindow =
  ## Create a new webview window
  var
    window: WebviewWindow
  new(window)
  window.webview = newWebView(title = title, url = url)
  window.webview.externalInvokeCB = proc(wv: Webview, data: string) =
    logging.debug "hi: " & data.repr
  app.windows.add(window)

template start*(app: WebviewApp) =
  ## Start the application loop
  app.launched.emit(true)
  var keepgoing = true
  while keepgoing:
    for window in app.windows:
      if loop(window.webview, 1) != 0:
        keepgoing = false
  app.willExit.emit(true)

var app* = newWebviewApp()
