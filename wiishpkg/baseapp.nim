import ./events
import os
import ospaths

type  
  BaseApplication* = ref object of RootRef
    launched*: EventSource[bool]
    willExit*: EventSource[bool]
  
  BaseWindow* = ref object of RootRef


when defined(wiishDev):
  import ./building/config
  proc resourcePath*(app: BaseApplication, filename: string): string =
    ## Return the path to a static resource included in the application
    let
      appdir = getAppDir()
      configPath = appdir/"wiish.toml"
      config = getMyOSConfig(configPath)
    result = joinPath(appdir, config.resourceDir, filename) # XXX this is not safe from going above resourcePath
else:
  proc resourcePath*(app: BaseApplication, filename: string): string =
    ## Return the path to a static resource included in the application
    let
      root = 
        when defined(ios):
          getAppDir()/"static"
        elif defined(android):
          "/android_asset"
        elif defined(macosx):
          normalizedPath(getAppDir()/"../Resources/resources").absolutePath()
        else:
          getAppDir()
    result = joinPath(root, filename) # XXX this is not safe from going above resourcePath