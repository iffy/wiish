## Module for making desktop Webview applications.
## Import from here regardless of the operating system
import webview
import macros
import strutils
import logging
import asyncdispatch
import tables
import json

import wiish/events ; export events
import wiish/logsetup
import wiish/baseapp ; export baseapp
import wiish/common ; export common

type
  IWebviewWindow* = concept win
    ## This is the interface required for a webview window
    win.onReady is EventSource[bool]
    win.onMessage is EventSource[string]
  
  IWebviewDesktopApp* = concept app
    ## These are the things needed for a webview desktop app
    app is IDesktopApp
    newWebviewDesktopApp() is ref typeof app
    app.start()
    app.life is EventSource[DesktopEvent]
    app.newWindow(url = string, title = string) is IWebviewWindow
    app.getWindow(int) is IWebviewWindow

type
  WebviewDesktopApp* = object
    windows: Table[int, ref WebviewWindow]
    life*: EventSource[DesktopEvent]
    nextWindowId: int
  
  WebviewWindow* = object
    webview*: Webview
    onReady*: EventSource[bool]
    onMessage*: EventSource[string]

const JS_PRELUDE = """
const readyrunner = {
  set: function(obj, prop, value) {
    if (prop === 'onReady') {
      value();
      window.external.invoke("ready:");
    }
    obj[prop] = value;
    return true;
  }
};
let onReadyFunc;
if (window.wiish && window.wiish.onReady) {
  onReadyFunc = window.wiish.onReady;
}
window.wiish = new Proxy({}, readyrunner);
window.wiish.handlers = [];
/**
  * Called by Nim code to transmit a message to JS.
  */
window.wiish._handleMessage = function(message) {
  for (let i = 0; i < wiish.handlers.length; i++) {
    wiish.handlers[i](message);
  }
};

/**
  *  Called by JS application code to watch for messages
  *  from Nim
  */
window.wiish.onMessage = function(handler) {
  wiish.handlers.push(handler);
};

/**
  *  Called by JS application code to send messages to Nim
  */
window.wiish.sendMessage = function(message) {
  window.external.invoke("msg:" + message);
};
if (onReadyFunc) { window.wiish.onReady = onReadyFunc; }
"""

proc newWebviewDesktopApp*(): ref WebviewDesktopApp =
  new(result)
  result[].life = newEventSource[DesktopEvent]()
  result[].windows = initTable[int, ref WebviewWindow]()

proc newWindow*(app: ref WebviewDesktopApp, title:string = "", url:string = "", width=640, height=480): ref WebviewWindow =
  ## Create a new webview window
  new(result)
  let w = result
  result.onReady = newEventSource[bool]()
  result.onMessage = newEventSource[string]()
  result.webview = newWebView(title = title, url = url, width = width, height = height)
  result.webview.externalInvokeCB = proc(wv: Webview, data: string) =
    let parts = data.split(":", 1)
    case parts[0]
    of "ready":
      w.onReady.emit(true)
    of "msg":
      w.onMessage.emit(parts[1])
    else:
      logging.warn "Unknown message: " & data.repr
  
  w.webview.dispatch(proc() =
    discard w.webview.eval(JS_PRELUDE)
  )
  
  # result.webview.eval("document.body = '<div>hi</div>'")
  let windowId = app.nextWindowId
  app.nextWindowId.inc()
  app.windows[windowId] = result

proc sendMessage*(win: ref WebviewWindow, message: string) =
  ## Send a message from Nim to JS
  # logging.debug "sendMessage not yet implemented"
  win.webview.dispatch(proc() =
    discard win.webview.eval("wiish._handleMessage(" & $ %message & ");")
  )

proc start*(app: ref WebviewDesktopApp) =
  ## Start the application loop
  startLogging()
  app.life.emit(DesktopEvent(kind: desktopAppStarted))
  var keepgoing = true
  while keepgoing:
    # Run window loops
    for windowId, window in app.windows.mpairs:
      if loop(window.webview, 1) != 0:
        keepgoing = false
    # Run asyncdispatch loop
    try:
      drain()
    except ValueError:
      discard
  app.life.emit(DesktopEvent(kind: desktopAppWillExit))


# isConcept(IDesktopApp, newWebviewDesktopApp())
# isConcept(IWebviewDesktopApp, newWebviewDesktopApp())
