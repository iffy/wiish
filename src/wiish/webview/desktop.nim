## Module for making desktop Webview applications.
import webview
import macros
import strutils
import logging
import json

import ../events
export events
import ../logsetup
import ../baseapp
import ./base

type
  WebviewDesktopApp* = ref object of RootRef
    windows*: seq[WebviewWindow]
    life*: DesktopLifecycle
  
  WebviewWindow* = ref object of RootRef
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

proc newWebviewDesktopApp*(): WebviewDesktopApp =
  new(result)
  result.life = newDesktopLifecycle()

proc newWindow*(app: WebviewDesktopApp, title:string = "", url:string = "", width=640, height=480): WebviewWindow =
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
  app.windows.add(result)

proc sendMessage*(win:WebviewWindow, message:string) =
  ## Send a message from Nim to JS
  # logging.debug "sendMessage not yet implemented"
  win.webview.dispatch(proc() =
    discard win.webview.eval("wiish._handleMessage(" & $ %message & ");")
  )

template start*(app: WebviewDesktopApp) =
  ## Start the application loop
  app.life.onStart.emit(true)
  var keepgoing = true
  while keepgoing:
    for window in app.windows:
      if loop(window.webview, 1) != 0:
        keepgoing = false
  app.life.onBeforeExit.emit(true)


isConcept(IDesktopApp, newWebviewDesktopApp())
isConcept(IWebviewDesktopApp, newWebviewDesktopApp())
