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

  # From SDL2 source, following:
  # - ./docs/README-android.md
  # - ./build-scripts/androidbuild.sh
  let
    config = getAndroidConfig(configPath)
    projectDir = directory/config.dst/"android"/"project"/config.java_package_name
    appSrc = directory/config.src
    sdlSrc = DATADIR/"SDL"
    appProject = projectDir/"app/jni/app"
    # androidNDKPath = getEnvOrFail("ANDROID_NDK", "Set to your local Android NDK path.  Download from https://developer.android.com/ndk/downloads/")
    # androidSDKPath = getEnvOrFail("ANDROID_SDK", "Set to your local Android SDK path.  Download from https://developer.android.com/studio/#downloads")
  var
    ndkArgs: seq[string]
  
  if not projectDir.existsDir():
    debug &"Copying SDL android project to {projectDir}"
    createDir(projectDir)
    copyDirWithPermissions(sdlSrc/"android-project", projectDir)

    # Copy in SDL source
    copyDirWithPermissions(sdlSrc/"src", projectDir/"app/jni/SDL/src")
    copyDirWithPermissions(sdlSrc/"include", projectDir/"app/jni/SDL/include")
    
    # Android.mk
    let android_mk = projectDir/"app/jni/SDL/Android.mk"
    copyFile(sdlSrc/"Android.mk", android_mk)
    replaceInFile(projectDir/"app/build.gradle", {
      "org.libsdl.app": config.java_package_name,
    }.toTable)
    replaceInFile(projectDir/"app/src/main/AndroidManifest.xml", {
      "org.libsdl.app": config.java_package_name,
    }.toTable)

  debug "Compiling Nim portion ..."
  proc buildFor(android_abi:string, cpu:string) =
    var nimFlags:seq[string]
    nimFlags.add(["nim", "c"])
    nimFlags.add([
      "--os:android",
      "-d:android",
      &"--cpu:{cpu}",
      # "--dynlibOverride:SDL2",
      "--noMain",
      "--header",
      "--compileOnly",
      # "--app:lib",
      # "--passL:-lGLESv1_CM",
      # "--passL:-lGLESv2",
      "--nimcache:" & projectDir/"app/jni/src"/android_abi,
      # "--out:" & appProject/arch_abi/"libmain.so",
      appSrc,
    ])
    debug nimFlags.join(" ")
    run(nimFlags)

  buildFor("armeabi-v7a", "arm")
  buildFor("arm64-v8a", "arm64")
  buildFor("x86", "i386")
  buildFor("x86_64", "amd64")
#   debug "Create application code Android.mk ..."
#   writeFile(appProject/"Android.mk", """
# LOCAL_PATH := $(call my-dir)

# include $(CLEAR_VARS)
# LOCAL_MODULE := main
# LOCAL_SRC_FILES := $(TARGET_ARCH_ABI)/libmain.so
# include $(PREBUILT_SHARED_LIBRARY)
# """)

  debug "Listing c files ..."
  var cfiles : seq[string]
  for item in walkDir(projectDir/"app/jni/src"):
    if item.kind == pcFile and item.path.endsWith(".c"):
      cfiles.add(item.path.basename)

  debug "Create Activity ..."
  let
    activity_prefix = config.java_package_name.split({'.'})[^1]
    activity_name = activity_prefix & "Activity"
    activity_java_path = projectDir/config.java_package_name.replace(".", "/")/activity_name&".java"
  activity_java_path.parentDir.createDir()
  debug activity_java_path
  writeFile(activity_java_path, &"""
package {config.java_package_name};

import org.libsdl.app.SDLActivity;

public class {activity_name} extends SDLActivity
{{
}}
""")

  replaceInFile(projectDir/"app/build.gradle", {
    "abiFilters.*?\n": "abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'\n",
  }.toTable)
  
  # if true:
  #   raise newException(CatchableError, "Need to copy in nimbase.h")
  
  let nimlib = getNimLibPath()
  debug &"nimlib: {nimlib}"
  writeFile(projectDir/"app/jni/src/Android.mk",
&"""
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := main
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../SDL/include {nimlib}
LOCAL_SRC_FILES := {cfiles.join(" ")}
LOCAL_SHARED_LIBRARIES := SDL2
LOCAL_LDLIBS := -lGLESv1_CM -lGLESv2 -llog

include $(BUILD_SHARED_LIBRARY)
""")

  debug &"Building with gradle in {projectDir} ..."
  withDir(projectDir):
    run("./gradlew", "installDebug")
  
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
