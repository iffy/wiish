## This module contains utilities for accessing files packaged
## with an application.
import ./baseapp
import os

when wiish_dev:
  import ./building/config

proc resourcePath*(filename: string): string =
  ## Return the path to a static resource included in the application
  when wiish_dev:
    let
      appdir = getAppDir()
      configPath = appdir/"wiish.toml"
      config = getMyOSConfig(configPath)
    result = joinPath(appdir, config.resourceDir, filename) # UNSAFE: this is not safe from going above resourcePath
    when defined(release):
      {.fatal: "You need to make the resourcePath safe".}
  else:
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
    result = joinPath(root, filename) # UNSAFE: this is not safe from going above resourcePath
    when defined(release):
      {.fatal: "You need to make the resourcePath safe".}