import std/dynlib
import std/logging
import std/os
import std/strutils

import jnim/private/jni_wrapper
import jnim/private/jvm_finder
export jni_wrapper

var global_JavaVM: JavaVMPtr
var global_JavaVersion: jint

type
  JavaVMAttachArgs* = object
    version: jint
    name: cstring
    group: jobject

proc jniErrorMessage*(err: jint): string =
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

proc ok*(rc: jint) =
  if rc != JNI_OK:
    raise newException(ValueError, "JNI Error: " & rc.jniErrorMessage())

proc initializeJavaVM*(env: JNIEnvPtr) =
  ## Set up the global_JavaVM
  ## Call this before doing anything else in here.
  debug "initializeJavaVM"
  let rc = env.GetJavaVM(env, global_JavaVM.addr)
  if rc != 0:
    error "Error getting JavaVM from JNIEnvPtr"
  global_JavaVersion = env.GetVersion(env)
  debug "JavaVersion: " & $global_JavaVersion
  # debug "global_JavaVM.isNil = " & $(global_JavaVM.isNil)
  # var handle = loadLib()
  # debug "handle.isNil = " & $(handle.isNil)
  # debug "JNI_CreateJavaVM addr isNil == " & $symAddr(handle, "JNI_CreateJavaVM").isNil
  # debug "foundJVM = " & $findJVM()
  # for f in walkDirRec("/system/lib/"):
  #   if f.endsWith(".so"):
  #     debug " + " & f
  #   else:
  #     debug " - " & f
  # debug "done walking"
  # # try:
  # #   linkWithJVMLib()
  # # except:
  # #   error "Error calling linkWithJVMLib(): " & getCurrentExceptionMsg()
  # #   raise
  # # debug "done linkWithJVMLib()"
  # if isJVMLoaded():
  #   var
  #     nVMs: jsize
  #   JNI_GetCreatedJavaVMs(global_JavaVM.addr, 1.jsize, nVMs.addr).ok()
  #   if nVMs.int == 0:
  #     error "Error finding JavaVM"
  #   global_JavaVersion = env.GetVersion(env)
  # else:
  #   error "isJVMLoaded() == false"

proc getJNIEnv(): JNIEnvPtr =
  doAssert not(global_JavaVM.isNil)
  let vm:JavaVM = global_JavaVM[]
  var initArgs = JavaVMAttachArgs(
    version: global_JavaVersion,
    name: "wiish",
    group: nil,
  )
  vm.AttachCurrentThread(global_JavaVM, cast[ptr pointer](result.addr), initArgs.addr).ok()

template withJEnv*(env: untyped, body: untyped): untyped =
  var env = getJNIEnv()
  try:
    body
  finally:
    let vm:JavaVM = global_JavaVM[]
    try:
      vm.DetachCurrentThread(global_JavaVM).ok()
    except:
      error "Error detaching jenv from thread: " & getCurrentExceptionMsg()
    
