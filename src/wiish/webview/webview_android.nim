## Module for making Android Webview applications.
when not defined(android):
  {.fatal: "Only available for -d:android".}

echo "========= START ============="

#----------------------------------------------------
# mini jni
#----------------------------------------------------
type
  JavaVM {.header: "<jni.h>", importc: "JavaVM".} = pointer
  JNIEnv {.header: "<jni.h>", importc: "JNIEnv".} = pointer
  jint* = int32
  # jsize* = jint
  # jchar* = uint16
  # jlong* = int64
  # jshort* = int16
  # jbyte* = int8
  # jfloat* = cfloat
  # jdouble* = cdouble
  # jboolean* = uint8

  jobject_base {.inheritable, pure.} = object
  jobject* = ptr jobject_base
  jstring* = ptr object of jobject
#----------------------------------------------------
# end of mini jni
#----------------------------------------------------

type
  WiishActivity = jobject

import memtools

# import jnim
import asyncdispatch
import locks
import logging
import options
import os
import strformat
import tables

import ../logsetup
import ./base ; export base

# jclass org.wiish.wiishexample.WiishActivity of JVMObject:
#   proc evalJavaScript*(js: string)
#   proc getInternalStoragePath*(): string

type
  MessageToMainKind = enum
    AppStarted
    AppWillExit
    WindowAdded
  MessageToMain = object
    case kind: MessageToMainKind
    of AppStarted, AppWillExit:
      discard
    of WindowAdded:
      windowId: int

var ch_to_main: Channel[MessageToMain]; ch_to_main.open()
var ch_main_setup: Channel[bool]; ch_main_setup.open()

type
  WebviewAndroidApp* = object
    url*: string
    life*: EventSource[MobileEvent]
    windows: Table[int, WebviewAndroidWindow]
    nextWindowId: int
  
  WebviewAndroidWindow* = object
    onReady*: EventSource[bool]
    onMessage*: EventSource[string]
    wiishActivity*: Option[WiishActivity]

var globalapplock: Lock
initLock(globalapplock)
var globalapp {.guard: globalapplock.}: ptr WebviewAndroidApp

proc `$`*(win: WebviewAndroidWindow): string =
  result = &"WebviewAndroidWindow()"

proc `$`*(app: WebviewAndroidApp): string =
  result = &"WebviewAndroidApp(url={app.url}, life={app.life}, windows={app.windows.len}, nextWindowId={app.nextWindowId})"

proc `$`*(win: ptr WebviewAndroidApp): string =
  if win.isNil:
    result = "WebviewAndroidApp==nil"
  else:
    result = "ptr[" & $win[] & "]"

proc newWebviewMobileApp*(): WebviewAndroidApp =
  {.gcsafe.}:
    globalapplock.withLock:
      if not globalapp.isNil:
        raise newException(ValueError, "Only one WebviewAndroidApp can be created at once")
      globalapp = createShared(WebviewAndroidApp)
      globalapp[].life = newEventSource[MobileEvent]()
      globalapp[].windows = initTable[int, WebviewAndroidWindow]()
      result = globalapp[]

proc newWebviewAndroidWindow*(): WebviewAndroidWindow =
  result = WebviewAndroidWindow()
  result.onReady = newEventSource[bool]()
  result.onMessage = newEventSource[string]()

proc getWindow*(app: WebviewAndroidApp, windowId: int): WebviewAndroidWindow {.inline.} =
  app.windows[windowId]

proc sendMessage*(win: WebviewAndroidWindow, message: string) =
  discard
  # TODO

template withJNI(body:untyped):untyped =
  body
  # if theEnv.isNil():
  #   checkInit()
  #   body
  # else:
  #   body

proc processMainMessage(msg: MessageToMain) =
  ## Handle messages sent from other threads to the main loop thread
  echo "Processing main message in thread : ", $getThreadId()
  case msg.kind
  else:
    echo "UNHANDLED: ", $msg

proc nimLoop() {.thread.} =
  ch_main_setup.send(true)
  try:
    while true:
      try:
        drain()
      except ValueError:
        discard
      # look for messages from other threads
      let resp = ch_to_main.tryRecv()
      if resp.dataAvailable:
        processMainMessage(resp.msg)
  except:
    echo "nimLoop exception: ", getCurrentExceptionMsg()
    echo "nimLoop stack:     ", getStackTrace()

proc startNimLoop() =
  var thread: Thread[void]
  createThread(thread, nimLoop)
  # wait for main loop to start...
  discard ch_main_setup.recv()

proc start*(app: WebviewAndroidApp, url: string) =
  startLogging()
  globalapplock.withLock:
    globalapp[].url = url
  startNimLoop()

#---------------------------------------------------
# JNI helpers
#
# These functions are used below in the JNI functions
#---------------------------------------------------
proc wiish_c_appStarted() {.exportc.} =
  ch_to_main.send(MessageToMain(kind: AppStarted))

proc wiish_c_appWillExit() {.exportc.} =
  ch_to_main.send(MessageToMain(kind: AppWillExit))

proc wiish_c_windowAdded(windowId: cint, activity: jobject) {.exportc.} =
  withJNI:
    var window = newWebviewAndroidWindow()
    window.wiishActivity = some(activity)
    globalapplock.withLock:
      globalapp.windows[windowId] = window
  ch_to_main.send(MessageToMain(kind: WindowAdded, windowId: windowId.int))

proc wiish_c_windowWillForeground(windowId: cint) {.exportc.} =
  discard
  # withJNI:
  #   globalapplock.withLock:
  #     globalapp.life.emit(MobileEvent(kind: WindowWillForeground, windowId: windowId))

proc wiish_c_windowDidForeground(windowId: cint) {.exportc.} =
  discard
  # withJNI:
  #   globalapplock.withLock:
  #     globalapp.life.emit(MobileEvent(kind: WindowDidForeground, windowId: windowId))

proc wiish_c_windowWillBackground(windowId: cint) {.exportc.} =
  discard
  # withJNI:
  #   globalapplock.withLock:
  #     globalapp.life.emit(MobileEvent(kind: WindowWillBackground, windowId: windowId))

proc wiish_c_windowClosed(windowId: cint) {.exportc.} =
  discard
  # withJNI:
  #   globalapplock.withLock:
  #     globalapp.life.emit(MobileEvent(kind: WindowClosed, windowId: windowId))

proc wiish_c_nextWindowId*(): cint {.exportc.} =
  ## Return the next Window ID to be used.
  globalapplock.withLock:
    result = globalapp.nextWindowId.cint
    inc globalapp.nextWindowId

proc wiish_c_getInitURL(): cstring {.exportc.} =
  ## Return the URL that a new window should open to.
  globalapplock.withLock:
    result = globalapp.url

proc wiish_c_sendMessageToNim(message:cstring) {.exportc.} =
  ## message sent from js to nim
  withJNI:
    let msg = $message
    # globalapplock.withLock:
    #   globalapp.window.onMessage.emit(msg)

proc wiish_c_signalJSIsReady() {.exportc.} =
  ## Child page is ready for messages
  # withJNI:
  #   globalapplock.withLock:
  #     globalapp.window.onReady.emit(true)

proc wiish_c_saveActivity(obj: jobject) {.exportc.} =
  ## Store the activity where Nim can get to it for sending
  ## messages to JavaScript
  # withJNI:
  #   globalapplock.withLock:
  #     globalapp.window.wiishActivity = WiishActivity.fromJObject(obj)


proc wiish_c_log(message: cstring) {.exportc.} =
  echo "WIISH LOG: ", $message

#---------------------------------------------------
# Exposed-to-Java functions
# TODO: How do I know the signature for adding these?
#---------------------------------------------------
{.emit: """
#include <org_wiish_exampleapp_WiishActivity.h> // This file is generated from WiishActivity.java by ./updateJNIheaders.sh
N_CDECL(void, NimMain)(void);

JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1init
(JNIEnv * env, jobject obj) {
  NimMain();
  wiish_c_appStarted();
}

JNIEXPORT jint JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1nextWindowId
(JNIEnv * env, jobject obj) {
  return wiish_c_nextWindowId();
}

JNIEXPORT jstring JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1getInitURL
(JNIEnv * env, jobject obj) {
  return (*env)->NewStringUTF(env, wiish_c_getInitURL());
}

JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1windowAdded
(JNIEnv * env, jobject obj, jint windowId) {
  jobject gobj = (*env)->NewGlobalRef(env, obj);
  wiish_c_windowAdded(windowId, gobj);
}

JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1sendMessageToNim
(JNIEnv * env, jobject obj, jstring str) {
  wiish_c_log("sendMessageToNim");
  const char *nativeString = (*env)->GetStringUTFChars(env, str, 0);
  wiish_c_sendMessageToNim(nativeString);
  (*env)->ReleaseStringUTFChars(env, str, nativeString);
}

JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1signalJSIsReady
(JNIEnv * env, jobject obj) {
  wiish_c_log("signalJSIsReady");
  wiish_c_signalJSIsReady();
}
""".}



# type
#   WebviewApp* = ref object of BaseApplication
#     window*: WebviewAndroidWindow
  
#   WebviewAndroidWindow* = ref object of WebviewWindow
#     onReady*: EventSource[bool]
#     onMessage*: EventSource[string]
#     wiishActivity*: WiishActivity

# proc newWebviewApp(): WebviewApp =
#   new(result)
#   result.launched = newEventSource[bool]()
#   result.willExit = newEventSource[bool]()
#   new(result.window)
#   result.window.onMessage = newEventSource[string]()
#   result.window.onReady = newEventSource[bool]()

# proc evalJavaScript*(win:WebviewAndroidWindow, js:string) =
#   ## Evaluate some JavaScript in the webview
#   var
#     activity = win.wiishActivity
#     javascript = js
#   activity.evalJavaScript(javascript)

# proc sendMessage*(win:WebviewAndroidWindow, message:string) =
#   ## Send a message from Nim to JS
#   evalJavaScript(win, &"wiish._handleMessage({%message});")
