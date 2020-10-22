## Module for making iOS Webview applications.
when not defined(ios):
  {.fatal: "webview_ios only works with ios".}
import asyncdispatch
import json
import locks
import logging
import net
import options
import strformat
import tables

import ../events ; export events
import ../logsetup
import ../baseapp ; export baseapp
import ./base ; export base

{.passL: "-framework Foundation" .}
{.passL: "-framework UIKit" .}
{.passL: "-framework WebKit" .}
{.emit: """
#include <CoreFoundation/CoreFoundation.h>
""" .}
  
type
  WebviewIosApp* = ref object of RootObj
    url*: string
    life*: EventSource[MobileEvent]
    windows: Table[int, WebviewIosWindow]
    nextWindowId: int
  
  WebviewIosWindow* = ref object of RootObj
    onReady*: EventSource[bool]
    onMessage*: EventSource[string]
    app: WebviewIosApp
    wiishController: Option[pointer]

var globalapplock {.global.}: Lock
initLock(globalapplock)

var globalapp {.global, guard: globalapplock.} : WebviewIosApp

proc newWebviewMobileApp*(): WebviewIosApp =
  new(result)
  result.life = newEventSource[MobileEvent]()
  result.windows = initTable[int, WebviewIosWindow]()

proc newWindow(app: WebviewIosApp): WebviewIosWindow =
  new(result)
  result.onReady = newEventSource[bool]()
  result.onMessage = newEventSource[string]()
  result.app = app

proc getWindow*(app: WebviewIosApp, windowId: int): WebviewIosWindow {.inline.} =
  app.windows[windowId]

proc nim_nextWindowId*(): cint {.exportc.} =
  ## Return the next Window ID to be used.
  globalapplock.withLock:
    result = globalapp.nextWindowId.cint
    inc globalapp.nextWindowId

proc nim_windowCreated*(windowId: cint, controller: pointer) {.exportc.} =
  ## A new window in iOS land.  Add it to the list
  globalapplock.withLock:
    var win = globalapp.newWindow()
    win.wiishController = some(controller)
    globalapp.windows[windowId.int] = win
    globalapp.life.emit(MobileEvent(kind: WindowAdded, windowId: windowId.int))

proc evalJavaScript*(win:WebviewIosWindow, js:string) =
  ## Evaluate some JavaScript in the webview
  # doAssert win.wiishController.isSome()
  var
    controller = win.wiishController.get()
    javascript:cstring = js
  {.emit: """
  [controller evalJavaScript:[NSString stringWithUTF8String:javascript]];
  """.}

proc sendMessage*(win:WebviewIosWindow, message:string) =
  ## Send a message from Nim to JS
  evalJavaScript(win, &"wiish._handleMessage({%message});")


proc nimLoop() {.exportc.} =
  setupForeignThreadGc()
  var do_run_forever = false
  try:
    poll()
    do_run_forever = true
  except ValueError:
    discard
  if do_run_forever:
    runForever()

proc startNimLoop(): Thread[void] =
  setupForeignThreadGc()
  createThread(result, nimLoop)

proc startIOSLoop(): cint {.importc.}

proc jsbridgecode(): cstring {.exportc.} =
  """
  const readyrunner = {
    set: function(obj, prop, value) {
      if (prop === 'onReady') {
        value();
        window.webkit.messageHandlers.wiish_internal_ready.postMessage('');
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
    window.webkit.messageHandlers.wiish.postMessage(message);
  };
  if (onReadyFunc) { window.wiish.onReady = onReadyFunc; }
  """

proc doLog(x:cstring) {.exportc.} =
  ## TODO: how do I call this from objc?
  debug(x)

#---------------------------------------------------
# lifecycle events
#---------------------------------------------------

proc nim_didFinishLaunching() {.exportc.} =
  globalapplock.withLock:
    globalapp.life.emit(MobileEvent(kind: AppStarted))

proc nim_windowWillBackground(windowId: cint) {.exportc.} =
  globalapplock.withLock:
    ## TODO: when multi-scene is supported, change the windowId appropriately
    globalapp.life.emit(MobileEvent(kind: WindowWillBackground, windowId: windowId.int))

proc nim_windowWillForeground(windowId: cint) {.exportc.} =
  globalapplock.withLock:
    globalapp.life.emit(MobileEvent(kind: WindowWillForeground, windowId: windowId.int))

proc nim_windowDidForeground(windowId: cint) {.exportc.} =
  globalapplock.withLock:
    globalapp.life.emit(MobileEvent(kind: WindowDidForeground, windowId: windowId.int))

proc nim_applicationWillTerminate() {.exportc.} =
  globalapplock.withLock:
    globalapp.life.emit(MobileEvent(kind: AppWillExit))


proc nim_signalJSMessagesReady(windowId: cint) {.exportc.} =
  var win: WebviewIosWindow
  globalapplock.withLock:
    win = globalapp.getWindow(windowId.int)
  win.onReady.emit(true)

proc nim_sendMessageToNim(windowId: cint, x:cstring) {.exportc.} =
  var win: WebviewIosWindow
  globalapplock.withLock:
    win = globalapp.getWindow(windowId.int)
  win.onMessage.emit($x)

proc getInitURL(): cstring {.exportc.} =
  globalapplock.withLock:
    result = globalapp.url

proc start*(app: WebviewIosApp, url: string) =
  ## Start the webview app at the given URL.
  globalapplock.withLock:
    globalapp = app
    app.url = url
  discard startNimLoop()
  discard startIOSLoop()

  
{.compile: "webview_ios_objc.m".}  
  


