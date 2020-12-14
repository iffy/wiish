## Module for making desktop Webview applications.
## Import from here regardless of the operating system
import webview
import strutils
import logging
import asyncdispatch
import tables
import json
import std/exitprocs

import wiish/events ; export events
import wiish/logsetup
import wiish/baseapp ; export baseapp
import wiish/common ; export common

const
  DEFAULT_WIDTH = when wiish_mobiledev: 375 else: 640
  DEFAULT_HEIGHT = when wiish_mobiledev: 667 else: 480

type
  WebviewApp* = ref object
    windows: Table[int, WebviewWindow]
    life*: EventSource[LifeEvent]
    nextWindowId: int
  
  WebviewWindow* = ref object
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

proc newWebviewApp*(): WebviewApp =
  new(result)
  result[].life = newEventSource[LifeEvent]()
  result[].windows = initTable[int, WebviewWindow]()

proc newWindow*(app: WebviewApp, title:string = "", url:string = "", width=DEFAULT_WIDTH, height=DEFAULT_HEIGHT): WebviewWindow =
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
  app.life.emit(LifeEvent(kind: WindowAdded, windowId: windowId))
  when wiish_mobiledev:
    app.life.emit(LifeEvent(kind: WindowWillForeground, windowId: windowId))
    app.life.emit(LifeEvent(kind: WindowDidForeground, windowId: windowId))

proc getWindow*(app: WebviewApp, windowId: int): WebviewWindow =
  app.windows[windowId]

proc sendMessage*(win: WebviewWindow, message: string) =
  ## Send a message from Nim to JS
  # logging.debug "sendMessage not yet implemented"
  win.webview.dispatch(proc() =
    discard win.webview.eval("wiish._handleMessage(" & $ %message & ");")
  )

proc start*(app: WebviewApp, url = "", title = "") =
  ## Start the application loop
  startLogging()
  app.life.emit(LifeEvent(kind: AppStarted))
  if url != "":
    discard app.newWindow(title = title, url = url)
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
  addExitProc proc() =
    for windowId in app.windows.keys:
      app.life.emit(LifeEvent(kind: WindowClosed, windowId: windowId))
    app.life.emit(LifeEvent(kind: AppWillExit))

# isConcept(IDesktopApp, newWebviewApp())
# isConcept(IWebviewApp, newWebviewApp())
