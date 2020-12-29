import os
import ./baseapp

#-----------------------------------------------------------
# File system
#-----------------------------------------------------------


when defined(ios):
  {.passL: "-framework Foundation" .}
  import darwin/objc/runtime
  import darwin/foundation
  proc NSHomeDirectory*(): NSString {.importc.}

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
    var activity = app.window.wiishActivity
    var path = activity.getInternalStoragePath()
    result = $path
  elif wiish_mobiledev:
    result = "_mobiledev" / "documents"
    createDir result
  else:
    raise newException(ValueError, "documentsPath not support on this OS")
