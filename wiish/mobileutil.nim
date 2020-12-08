import os
import ./webview_mobile

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
  when defined(ios):
    # iOS doesn't need an app ref but Android does
    $(NSHomeDirectory().UTF8String()) / "Documents"
  elif defined(android):
    var activity = app.window.wiishActivity
    var path = activity.getInternalStoragePath()
    result = $path