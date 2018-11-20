## Webview Application
import webview
import macros
import times
import logging

import ./app_common
export app_common
import ../events

type
  WebviewApp* = ref object of BaseApplication
    windows*: seq[WebviewWindow]
  
  WebviewWindow* = ref object of BaseWindow
    webview*: Webview

proc createApplication*(): WebviewApp =
  new(result)
  result.launched = newEventSource[bool]()
  result.willExit = newEventSource[bool]()

proc newWindow*(app: WebviewApp, title:string = "", url:string = ""): WebviewWindow =
  ## Create a new webview-based window
  var
    window: WebviewWindow
  new(window)
  window.webview = newWebView(title = title, url = url)
  window.webview.externalInvokeCB = proc(wv: Webview, data: string) =
    logging.debug "hi: " & data.repr
  app.windows.add(window)

template start*(app: WebviewApp) =
  app.launched.emit(true)
  var keepgoing = true
  while keepgoing:
    for window in app.windows:
      if loop(window.webview, 1) != 0:
        keepgoing = false
  app.willExit.emit(true)

proc quit*(app: WebviewApp) =
  warn "quit NOT IMPLEMENTED"