import os
import ./baseapp

#-----------------------------------------------------------
# File system
#-----------------------------------------------------------


when wiish_ios:
  {.passL: "-framework Foundation" .}
  import darwin/objc/runtime
  import darwin/foundation
  proc NSHomeDirectory*(): NSString {.importc.}
elif wiish_android:
  import ./androidutil

proc documentsPath*():string =
  ## Get the path to a mobile app's private document storage directory
  ##
  ## On iOS, this is the app's Documents directory.
  ## On Android, this is the root of the internal storage directory.
  ## On mobiledev, this is '_mobiledev/Documents'
  when wiish_ios:
    # iOS doesn't need an app ref but Android does
    $(NSHomeDirectory().UTF8String()) / "Documents"
  elif wiish_android:
    withJEnv(env):
      let activityThreadClass = env.FindClass(env, "android/app/ActivityThread")
      let currentActivityThread = env.GetStaticMethodID(env, activityThreadClass, "currentActivityThread", "()Landroid/app/ActivityThread;")
      let at = env.CallStaticObjectMethod(env, activityThreadClass, currentActivityThread)

      let getApplication = env.GetMethodID(env, activityThreadClass, "getApplication", "()Landroid/app/Application;")
      let context = env.CallObjectMethod(env, at, getApplication)

      let contextClass = env.FindClass(env, "android/content/Context")
      let getFilesDir = env.GetMethodID(env, contextClass, "getFilesDir", "()Ljava/io/File;")
      let filesDir = env.CallObjectMethod(env, context, getFilesDir)

      let fileClass = env.FindClass(env, "java/io/File")
      let getPath = env.GetMethodID(env, fileClass, "getPath", "()Ljava/lang/String;")
      let path = cast[jstring](env.CallObjectMethod(env, filesDir, getPath))
      var dummybool: jboolean
      let native_string = env.GetStringUTFChars(env, path, dummybool.addr)
      result = $native_string
      env.ReleaseStringUTFChars(env, path, native_string)
  elif wiish_mobiledev:
    result = "_mobiledev" / "documents"
    createDir result
  else:
    raise newException(ValueError, "documentsPath not support on this OS")
