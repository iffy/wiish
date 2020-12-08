## This module contains utilities for accessing files packaged
## with an application.
import ./baseapp
import strformat
import strutils
import os

when wiish_dev:
  import ./building/config

proc assertWithinDir(path: string, dir: string) =
  ## Assert that path is a file/dir within dir
  let a = dir.absolutePath()
  let b = path.absolutePath()
  if not b.startsWith(a):
    raise ValueError.newException(&"{path} is not a child to {dir}")

proc resourceDir*(): string =
  ## Return the absolute path to the directory where resources are
  ## for this app.
  when wiish_dev:
    let
      appdir = getAppDir()
      configPath = appdir/"wiish.toml"
      config = getMyOSConfig(configPath)
    result = joinPath(appdir, config.resourceDir)
  elif defined(ios):
    result = getAppDir()/"static"
  elif defined(android):
    result = "/android_asset"
  elif defined(macosx):
    result = normalizedPath(getAppDir()/"../Resources/resources").absolutePath()
  else:
    echo "Warning, resource dir not well defined"
    result = getAppDir()

proc resourcePath*(filename: string): string =
  ## Return the path to a static resource included in the application
  ## As a safety measure, this will not return a file outside of the
  ## application's resource dir.
  let dir = resourceDir()
  result = joinPath(dir, filename)
  result.assertWithinDir(dir)
