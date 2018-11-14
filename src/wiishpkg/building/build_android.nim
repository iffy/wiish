import os
import osproc
import re
import ospaths
import logging
import strformat
import strutils
import tables
import posix
import parsetoml

import ./config
import ./buildutil

proc getEnvOrFail(name: string, errmessage: string = ""): string =
  if existsEnv(name):
    getEnv(name)
  else:
    raise newException(CatchableError, &"Environment variable {name} must be set.  {errmessage}")

proc replaceInFile(filename: string, replacements: Table[string, string]) =
  ## Replace lines in a file with the given replacements
  var guts = filename.readFile()
  for pattern, replacement in replacements:
    guts = guts.replace(re(pattern), replacement)
  filename.writeFile(guts)

proc doAndroidBuild*(directory:string, configPath:string): string =
  ## Package an Android app
  ## Returns the path to the app

  # Following the SDL2 Android README in the SDL2 source
  # look in SDL2SOURCE/docs/README-android.md
  let
    config = getAndroidConfig(configPath)
    projectDir = directory/config.dst/"android"/"project"
    appSrc = directory/config.src
    sdlSrc = DATADIR/"SDL"
    # androidNDKPath = getEnvOrFail("ANDROID_NDK", "Set to your local Android NDK path.  Download from https://developer.android.com/ndk/downloads/")
    # androidSDKPath = getEnvOrFail("ANDROID_SDK", "Set to your local Android SDK path.  Download from https://developer.android.com/studio/#downloads")
  var
    nimFlags: seq[string]
    ndkArgs: seq[string]
  
  if not projectDir.existsDir():
    debug &"Copying SDL android project to {projectDir}"
    createDir(projectDir)
    copyDirWithPermissions(sdlSrc/"android-project", projectDir)
    copyDirWithPermissions(sdlSrc, projectDir/"app/jni/SDL")

  debug "Compiling Nim portion ..."
  nimFlags.add(["nim", "c"])
  nimFlags.add([
    "--os:linux",
    "-d:android",
    "--compileOnly",
    # "--cpu:x86_64",
    "--dynlibOverride:SDL2",
    "--noMain",
    "--header",
    "--nimcache:" & projectDir/"app/jni/src",
    appSrc,
  ])
  debug nimFlags.join(" ")
  run(nimFlags)

  if true:
    raise newException(CatchableError, "Need to copy in nimbase.h")

  replaceInFile(projectDir/"app/jni/src/Android.mk", {
    # XXX This is hard-coded to wiish_main_mobile.c right now, but should
    # instead be based on the actual c code
    "LOCAL_SRC_FILES.*?\n": "LOCAL_SRC_FILES := wiish_main_mobile.c\n",
  }.toTable)

  debug "Building with gradle ..."
  run(projectDir/"gradlew", "installDebug")
  
  # debug "Doing NDK build ..."
  # ndkArgs.add(androidNDKPath/"ndk-build")
  # ndkArgs.add(@[
  #   "--directory=" & buildPackageDir,
  #   "V=1", # Verbose
  #   "NDK_DEBUG=1", # Debug
  #   "APP_OPTIM=debug", # Debug
  # ])
  # debug ndkArgs.join(" ")
  # run(ndkArgs)

  echo "Android IS NOT SUPPORTED YET"

proc doAndroidRun*(directory: string) =
  discard
