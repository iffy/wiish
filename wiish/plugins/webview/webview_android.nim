## Module for making Android Webview applications.
when not defined(android):
  {.fatal: "Only available for -d:android".}

import asyncdispatch
import jnim/private/jni_wrapper
import json
import locks
import logging
import options
import strformat
import tables

import wiish/logsetup
import wiish/baseapp ; export baseapp

type
  MessageToMainKind = enum
    StdMobileEvent
    JsIsReady
    MessageFromJavaScript
  MessageToMain = object
    case kind: MessageToMainKind
    of StdMobileEvent:
      mobile_ev: MobileEvent
    of JsIsReady:
      windowId: int
    of MessageFromJavaScript:
      js_message_windowId: int
      js_message: string

var ch_to_main: Channel[MessageToMain]; ch_to_main.open()
var ch_main_setup: Channel[bool]; ch_main_setup.open()

type
  WebviewAndroidApp* = object
    url*: string
    life*: EventSource[MobileEvent]
    windows: Table[int, ref WebviewAndroidWindow]
    nextWindowId: int
  
  WebviewAndroidWindow* = object
    onReady*: EventSource[bool]
    onMessage*: EventSource[string]
    wiishActivity*: Option[WiishActivity]

  WiishActivity = jobject

var global_JavaVM: JavaVMPtr
var global_JavaVersion: jint

type
  JavaVMAttachArgs = object
    version: jint
    name: cstring
    group: jobject

proc jniErrorMessage(err: jint): string =
  ## Convert an error return code into a string
  result = case err
    of JNI_ERR: "Error"
    of JNI_EDETACHED: "Error detached"
    of JNI_EVERSION: "Error version"
    of JNI_ENOMEM: "Error no memory"
    of JNI_EEXIST: "Error exist"
    of JNI_EINVAL: "Error invalid"
    else: "Unknown error"
  result.add " " & $err.int

proc ok(rc: jint) =
  if rc != JNI_OK:
    raise newException(ValueError, "JNI Error: " & rc.jniErrorMessage())

proc initializeJavaVM(env: JNIEnvPtr) =
  ## Set up the global_JavaVM
  linkWithJVMLib()
  if isJVMLoaded():
    var
      nVMs: jsize
    JNI_GetCreatedJavaVMs(global_JavaVM.addr, 1.jsize, nVMs.addr).ok()
    if nVMs.int == 0:
      error "Error finding JavaVM"
    global_JavaVersion = env.GetVersion(env)

proc getJNIEnv(): JNIEnvPtr =
  doAssert not(global_JavaVM.isNil)
  let vm:JavaVM = global_JavaVM[]
  var initArgs = JavaVMAttachArgs(
    version: global_JavaVersion,
    name: "wiish",
    group: nil,
  )
  vm.AttachCurrentThread(global_JavaVM, cast[ptr pointer](result.addr), initArgs.addr).ok()

template withJEnv(env: untyped, body: untyped): untyped =
  var env = getJNIEnv()
  try:
    body
  finally:
    let vm:JavaVM = global_JavaVM[]
    try:
      vm.DetachCurrentThread(global_JavaVM).ok()
    except:
      error "Error detaching jenv from thread: " & getCurrentExceptionMsg()
    


var globalapplock: Lock
initLock(globalapplock)
var globalapp {.guard: globalapplock.}: ptr WebviewAndroidApp

proc newWebviewMobileApp*(): ptr WebviewAndroidApp =
  {.gcsafe.}:
    globalapplock.withLock:
      if not globalapp.isNil:
        raise newException(ValueError, "Only one WebviewAndroidApp can be created at once")
      globalapp = createShared(WebviewAndroidApp)
      globalapp[].life = newEventSource[MobileEvent]()
      globalapp[].windows = initTable[int, ref WebviewAndroidWindow]()
      result = globalapp

proc newWebviewAndroidWindow*(): ref WebviewAndroidWindow =
  new(result)
  result.onReady = newEventSource[bool]()
  result.onMessage = newEventSource[string]()

proc getWindow*(app: ptr WebviewAndroidApp, windowId: int): ref WebviewAndroidWindow {.inline.} =
  app.windows[windowId]

proc evalJavaScript(win: ref WebviewAndroidWindow, js: string) =
  ## Evaluate some JavaScript in the webview
  if win.wiishActivity.isNone:
    warn "Attempting to execute JavaScript in unattached webview window"
  else:
    var
      activity = win.wiishActivity.get()
      javascript = js.cstring
    withJEnv(env):
      var cls: JClass = env.GetObjectClass(env, activity)
      var mid: jmethodID = env.GetMethodID(env, cls, "evalJavaScript", "(Ljava/lang/String;)V");
      if mid.isNil:
        raise newException(ValueError, "Failed to get evalJavaScript methodId")
      var jstring_js = env.NewStringUTF(env, js)
      env.CallVoidMethod(env, activity, mid, jstring_js)

proc sendMessage*(win: ref WebviewAndroidWindow, message: string) =
  ## Send a string message to the JavaScript in the window's webview
  win.evalJavaScript(&"wiish._handleMessage({%message});")

proc processMainMessage(msg: MessageToMain) {.gcsafe.} =
  ## Handle messages sent from other threads to the main loop thread
  case msg.kind
  of StdMobileEvent:
    globalapplock.withLock:
      {.gcsafe.}:
        globalapp.life.emit(msg.mobile_ev)
  of JsIsReady:
    globalapplock.withLock:
      {.gcsafe.}:
        globalapp.windows[msg.windowId].onReady.emit(true)
  of MessageFromJavaScript:
    globalapplock.withLock:
      {.gcsafe.}:
        globalapp.windows[msg.js_message_windowId].onMessage.emit(msg.js_message)

proc nimLoop() {.thread, gcsafe.} =
  ## The main async nim loop
  startLogging()
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
    error "nimLoop exception: ", getCurrentExceptionMsg()
    error "nimLoop stack:     ", getStackTrace()

proc startNimLoop() =
  var thread: Thread[void]
  createThread(thread, nimLoop)
  # wait for main loop to start...
  discard ch_main_setup.recv()

proc start*(app: ptr WebviewAndroidApp, url: string) =
  startLogging()
  globalapplock.withLock:
    globalapp.url = url
    
  startNimLoop()

#---------------------------------------------------
# JNI helpers
#
# These functions are used below in the JNI functions
# Assume that these are NOT being run on the main thread
#---------------------------------------------------
proc wiish_c_initVM(env: JNIEnvPtr) {.exportc.} =
  env.initializeJavaVM()

proc wiish_c_appStarted() {.exportc.} =
  ch_to_main.send(MessageToMain(kind: StdMobileEvent,
    mobile_ev: MobileEvent(kind: AppStarted)))

proc wiish_c_appWillExit() {.exportc.} =
  ch_to_main.send(MessageToMain(kind: StdMobileEvent,
    mobile_ev: MobileEvent(kind: AppWillExit)))

proc wiish_c_windowAdded(windowId: cint, activity: jobject) {.exportc.} =
  var window = newWebviewAndroidWindow()
  window.wiishActivity = some(activity)
  globalapplock.withLock:
    globalapp.windows[windowId] = window
  ch_to_main.send(MessageToMain(kind: StdMobileEvent,
    mobile_ev: MobileEvent(kind: WindowAdded, windowId: windowId.int)))

proc wiish_c_windowWillForeground(windowId: cint) {.exportc.} =
  ch_to_main.send(MessageToMain(kind: StdMobileEvent,
    mobile_ev: MobileEvent(kind: WindowWillForeground, windowId: windowId)))

proc wiish_c_windowDidForeground(windowId: cint) {.exportc.} =
  ch_to_main.send(MessageToMain(kind: StdMobileEvent,
    mobile_ev: MobileEvent(kind: WindowDidForeground, windowId: windowId)))

proc wiish_c_windowWillBackground(windowId: cint) {.exportc.} =
  ch_to_main.send(MessageToMain(kind: StdMobileEvent,
    mobile_ev: MobileEvent(kind: WindowWillBackground, windowId: windowId)))

proc wiish_c_windowClosed(windowId: cint) {.exportc.} =
  ch_to_main.send(MessageToMain(kind: StdMobileEvent,
    mobile_ev: MobileEvent(kind: WindowClosed, windowId: windowId)))

proc wiish_c_nextWindowId*(): cint {.exportc.} =
  ## Return the next Window ID to be used.
  globalapplock.withLock:
    result = globalapp.nextWindowId.cint
    inc globalapp.nextWindowId

proc wiish_c_getInitURL(): cstring {.exportc.} =
  ## Return the URL that a new window should open to.
  globalapplock.withLock:
    result = globalapp.url

proc wiish_c_sendMessageToNim(windowId: cint, message:cstring) {.exportc.} =
  ## message sent from js to nim
  ch_to_main.send(MessageToMain(kind: MessageFromJavaScript,
    js_message: $message,
    js_message_windowId: windowId))

proc wiish_c_signalJSIsReady(windowId: cint) {.exportc.} =
  ## Child page is ready for messages
  ch_to_main.send(MessageToMain(kind: JsIsReady, windowId: windowId))

proc wiish_c_log(message: cstring) {.exportc.} =
  echo "WIISH LOG: ", $message

#---------------------------------------------------
# Exposed-to-Java functions
# TODO: How do I know the signature for adding these?
#
# After adding/removing/changing function signatures below
# 1. Update WiishActivity.java by hand
# 2. Run ./updateJNIheaders.sh to update org_wiish_exampleapp_WiishActivity.h
#---------------------------------------------------
{.emit: """
#include <org_wiish_exampleapp_WiishActivity.h> // This file is generated from WiishActivity.java by ./updateJNIheaders.sh
N_CDECL(void, NimMain)(void);
JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1init
(JNIEnv * env, jobject obj) {
  NimMain();
  wiish_c_initVM(env);
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
(JNIEnv * env, jobject obj, jint windowId, jstring str) {
  //wiish_c_log("sendMessageToNim");
  const char *nativeString = (*env)->GetStringUTFChars(env, str, 0);
  wiish_c_sendMessageToNim(windowId, nativeString);
  (*env)->ReleaseStringUTFChars(env, str, nativeString);
}

JNIEXPORT void JNICALL Java_org_wiish_exampleapp_WiishActivity_wiish_1signalJSIsReady
(JNIEnv * env, jobject obj, jint windowId) {
  wiish_c_signalJSIsReady(windowId);
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
