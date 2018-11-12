import os
import osproc
import ospaths
import logging
import strformat
import posix
import parsetoml

import ./config
import ./buildutil

proc doAndroidBuild*(directory:string, configPath:string): string =
  ## Package an Android app
  ## Returns the path to the app
  let
    config = getAndroidConfig(configPath)
    buildDir = directory/config.dst/"android"
    appSrc = directory/config.src
  
  debug &"Copying SDL android project to {buildDir}"
  createDir(buildDir)
  copyDir(DATADIR/"sdl2src/android-project", buildDir)

  echo "Android IS NOT SUPPORTED YET"

proc doAndroidRun*(directory: string) =
  discard
