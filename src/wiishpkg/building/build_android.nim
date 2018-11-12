import os
import osproc
import ospaths
import logging
import strformat
import strutils
import posix
import parsetoml

import ./config
import ./buildutil

proc getEnvOrFail(name: string, errmessage: string = ""): string =
  if existsEnv(name):
    getEnv(name)
  else:
    raise newException(CatchableError, &"Environment variable {name} must be set.  {errmessage}")

proc doAndroidBuild*(directory:string, configPath:string): string =
  ## Package an Android app
  ## Returns the path to the app
  let
    config = getAndroidConfig(configPath)
    buildDir = directory/config.dst/"android"/"build"
    buildPackageDir = buildDir/config.java_package_name
    appSrc = directory/config.src
    sdlSrc = DATADIR/"sdl2src"
    androidNDKPath = getEnvOrFail("ANDROID_NDK", "Set to your local Android NDK path.  Download from https://developer.android.com/ndk/downloads/")
    androidSDKPath = getEnvOrFail("ANDROID_SDK", "Set to your local Android SDK path.  Download from https://developer.android.com/studio/#downloads")
  var
    nimFlags: seq[string]
    ndkArgs: seq[string]
  
  if not buildPackageDir.existsDir():
    debug &"Copying SDL android project to {buildPackageDir}"
    createDir(buildPackageDir)
    copyDir(sdlSrc/"android-project", buildPackageDir)
    createDir(buildPackageDir/"jni/SDL")
    copyDir(sdlSrc/"src", buildPackageDir/"jni/SDL/src")
    copyDir(sdlSrc/"include", buildPackageDir/"jni/SDL/include")
    copyFile(sdlSrc/"Android.mk", buildPackageDir/"jni/SDL/Android.mk")

  debug "Compiling Nim portion ..."
  nimFlags.add(["nim", "c"])
  nimFlags.add([
    "--os:linux",
    "-d:android",
    "--compileOnly",
    "--cpu:arm",
    "--dynlibOverride:SDL2",
    "--noMain",
    "--warning[LockLevel]:off",
    "--verbosity:0",
    "--hint[Pattern]:off",
    "--parallelBuild:0",
    "--nimcache:" & buildPackageDir/"jni/src",
    appSrc,
    ])
  debug nimFlags.join(" ")
  run(nimFlags)
  
  debug "Doing NDK build ..."
  ndkArgs.add(androidNDKPath/"ndk-build")
  ndkArgs.add(@[
    "--directory=" & buildPackageDir,
    "V=1", # Verbose
    "NDK_DEBUG=1", # Debug
    "APP_OPTIM=debug", # Debug
  ])
  debug ndkArgs.join(" ")
  run(ndkArgs)

  echo "Android IS NOT SUPPORTED YET"

proc doAndroidRun*(directory: string) =
  discard
