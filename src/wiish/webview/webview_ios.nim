## Module for making iOS Webview applications.
when not defined(ios):
  {.fatal: "webview_ios only works with ios".}
import net
import asyncdispatch
import json
import strformat
import logging
import locks

import ../events
export events
import ../logsetup
import ../baseapp
export baseapp
import ./base
export base

{.passL: "-framework Foundation" .}
{.passL: "-framework UIKit" .}
{.passL: "-framework WebKit" .}
  
type
  WebviewIosApp* = ref object of RootObj
    url*: string
    window*: WebviewIosWindow
    life*: EventSource[MobileEvent]
  
  WebviewIosWindow* = ref object of RootObj
    onReady*: EventSource[bool]
    onMessage*: EventSource[string]
    wiishController*: pointer

var globalapplock {.global.}: Lock
initLock(globalapplock)

var globalapp {.global, guard: globalapplock.} : WebviewIosApp

proc newWebviewMobileApp*(): WebviewIosApp =
  new(result)
  new(result.window)
  result.life = newEventSource[MobileEvent]()

proc registerWiishController*(controller: pointer) {.exportc.} =
  ## Register the controller with the global app
  globalapplock.withLock:
    globalapp.window.wiishController = controller

proc evalJavaScript*(win:WebviewIosWindow, js:string) =
  ## Evaluate some JavaScript in the webview
  var
    controller = win.wiishController
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
  debug(x)

#---------------------------------------------------
# lifecycle events
#---------------------------------------------------

proc nim_didFinishLaunching() {.exportc.} =
  globalapplock.withLock:
    globalapp.life.emit(MobileEvent(kind: AppStarted))

proc nim_applicationWillResignActive() {.exportc.} =
  globalapplock.withLock:
    ## TODO: when multi-scene is supported, change the windowId appropriately
    globalapp.life.emit(MobileEvent(kind: WindowWillBackground, windowId: 0))

proc nim_applicationWillEnterForeground() {.exportc.} =
  globalapplock.withLock:
    globalapp.life.emit(MobileEvent(kind: WindowWillForeground, windowId: 0))

proc nim_applicationDidBecomeActive() {.exportc.} =
  globalapplock.withLock:
    globalapp.life.emit(MobileEvent(kind: WindowDidForeground, windowId: 0))

proc nim_applicationWillTerminate() {.exportc.} =
  globalapplock.withLock:
    globalapp.life.emit(MobileEvent(kind: AppWillExit))


proc nim_signalJSMessagesReady() {.exportc.} =
  # debug "nim_signalJSMessagesReady"
  globalapplock.withLock:
    globalapp.window.onReady.emit(true)

proc nim_sendMessageToNim(x:cstring) {.exportc.} =
  # debug "nim_sendMessageToNim: " & $x
  globalapplock.withLock:
    globalapp.window.onMessage.emit($x)

proc getInitURL(): cstring {.exportc.} =
  globalapplock.withLock:
    result = globalapp.url

proc nimwin(): WebviewIosWindow {.exportc.} =
  globalapplock.withLock:
    result = globalapp.window

proc start*(app: WebviewIosApp, url: string) =
  ## Start the webview app at the given URL.
  globalapplock.withLock:
    globalapp = app
    app.url = url
  discard startNimLoop()
  discard startIOSLoop()

  
{.compile: "webview_ios_objc.m".}  
  


