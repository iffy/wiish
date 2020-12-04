import os
import osproc
import re
import logging
import strformat
import strutils
import tables
import parsetoml

import ./config
import ./buildutil

proc replaceInFile(filename: string, replacements: Table[string, string]) =
  ## Replace lines in a file with the given replacements
  var guts = filename.readFile()
  for pattern, replacement in replacements:
    guts = guts.replace(re(pattern), replacement)
  filename.writeFile(guts)

template activityName(config: WiishConfig):string =
  config.java_package_name.split({'.'})[^1] & "Activity"

template fullActivityName(config: WiishConfig):string =
  ## Return the java.style.activity.name of an app
  config.java_package_name & "." & config.activityName()

proc doAndroidBuild*(directory:string, config: WiishConfig): string =
  ## Package an Android app
  ## Returns the path to the app

  # From SDL2 source, following:
  # - ./docs/README-android.md
  # - ./build-scripts/androidbuild.sh
  let
    projectDir = directory/config.dst/"android"/"project"/config.java_package_name
    appSrc = directory/config.src
    sdlSrc = DATADIR()/"SDL"
    webviewSrc = DATADIR()/"android-webview"
    # appProject = projectDir/"app"/"jni"/"app"
    srcResources = directory/config.resourceDir
    dstResources = projectDir/"app"/"src"/"main"/"assets"
    # androidNDKPath = getEnvOrFail("ANDROID_NDK", "Set to your local Android NDK path.  Download from https://developer.android.com/ndk/downloads/")
    # androidSDKPath = getEnvOrFail("ANDROID_SDK", "Set to your local Android SDK path.  Download from https://developer.android.com/studio/#downloads")

  if projectDir.dirExists():
    projectDir.removeDir()

  if config.windowFormat == SDL:
    if not projectDir.dirExists():
      debug &"Copying SDL android project to {projectDir}"
      createDir(projectDir)
      copyDirWithPermissions(sdlSrc/"android-project", projectDir)

      # Copy in SDL source
      copyDirWithPermissions(sdlSrc/"src", projectDir/"app"/"jni"/"SDL"/"src")
      copyDirWithPermissions(sdlSrc/"include", projectDir/"app"/"jni"/"SDL"/"include")
      let android_mk = projectDir/"app"/"jni"/"SDL"/"Android.mk"
      copyFile(sdlSrc/"Android.mk", android_mk)

      # build.gradle
      replaceInFile(projectDir/"app"/"build.gradle", {
        "org.libsdl.app": config.java_package_name,
      }.toTable)

      # AndroidManifest.xml
      replaceInFile(projectDir/"app"/"src"/"main"/"AndroidManifest.xml", {
        "org.libsdl.app": config.java_package_name,
      }.toTable)

  elif config.windowFormat == Webview:
    if not projectDir.dirExists():
      debug &"Copying Android template project to {projectDir}"
      createDir(projectDir)
      copyDirWithPermissions(webviewSrc, projectDir)

      # build.gradle
      replaceInFile(projectDir/"app"/"build.gradle", {
        "org.wiish.exampleapp": config.java_package_name,
      }.toTable)

      # AndroidManifest.xml
      replaceInFile(projectDir/"app"/"src"/"main"/"AndroidManifest.xml", {
        "org.wiish.exampleapp": config.java_package_name,
      }.toTable)

  debug "Compiling Nim portion ..."
  proc buildFor(android_abi:string, cpu:string) =
    let nimcachedir = projectDir/"app"/"jni"/"src"/android_abi
    if nimcachedir.dirExists:
      nimcachedir.removeDir()
    var nimFlags:seq[string]
    nimFlags.add(["nim", "c"])
    nimFlags.add(config.nimflags)
    nimFlags.add([
      "--os:android",
      "-d:android",
      "-d:androidNDK",
      &"--cpu:{cpu}",
      "--noMain:on",
      "--gc:orc",
      "--header",
      "--threads:on",
      "--tlsEmulation:off",
      "--hints:off",
      "--compileOnly",
      &"-d:appJavaPackageName={config.java_package_name}",
      "--nimcache:" & nimcachedir,
      appSrc,
    ])
    debug nimFlags.join(" ")
    run(nimFlags)
    
    let
      nimbase_dst = projectDir/"app"/"jni"/"src"/android_abi/"nimbase.h"
      nimversion = execCmdEx("nim --version").output.split(" ")[3]
      nimminor = nimversion.rsplit(".", 1)[0]
    debug &"Writing {nimbase_dst} for Nim version {nimminor} ..."
    let nimbase_h = case nimminor
      of "1.0": NIMBASE_1_0_X
      of "1.2": NIMBASE_1_2_X
      of "1.4": NIMBASE_1_4_x
      else:
        raise ValueError.newException("Unsupported Nim version: " & nimversion)
    nimbase_dst.writeFile(nimbase_h)

  # Android ABIs: https://developer.android.com/ndk/guides/android_mk#taa
  # nim --cpus: https://github.com/nim-lang/Nim/blob/devel/lib/system/platforms.nim#L14
  buildFor("armeabi-v7a", "arm")
  buildFor("arm64-v8a", "arm64")
  buildFor("x86", "i386")
  buildFor("x86_64", "amd64")

# # https://developer.android.com/ndk/guides/prebuilts
#   debug "Create application code Android.mk ..."
#   writeFile(appProject/"Android.mk", """
# LOCAL_PATH := $(call my-dir)

# include $(CLEAR_VARS)
# LOCAL_MODULE := main
# LOCAL_SRC_FILES := $(TARGET_ARCH_ABI)/libmain.so
# include $(PREBUILT_SHARED_LIBRARY)
# """)

  debug "Create Activity ..."
  let
    activity_name = config.activityName()
    activity_java_path = projectDir/"app"/"src"/"main"/"java"/config.java_package_name.replace(".", "/")/activity_name&".java"
  activity_java_path.parentDir.createDir()
  
  var cfiles : seq[string]
  debug "Listing c files ..."
  for item in walkDir(projectDir/"app"/"jni"/"src"/"x86"):
    if item.kind == pcFile and item.path.endsWith(".c"):
      cfiles.add("$(TARGET_ARCH_ABI)"/(&"{item.path.extractFilename}"))
  
  replaceInFile(projectDir/"app"/"build.gradle", {
    "abiFilters.*?\n": "abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'\n",
  }.toTable)

  if config.windowFormat == SDL:
    #---------------------------------------
    # SDL
    #---------------------------------------
    writeFile(activity_java_path, &"""
package {config.java_package_name};

import org.libsdl.app.SDLActivity;

public class {activity_name} extends SDLActivity
{{
}}
""")
    replaceInFile(projectDir/"app"/"src"/"main"/"AndroidManifest.xml", {
      "SDLActivity": activity_name,
    }.toTable)
    writeFile(projectDir/"app"/"jni"/"src"/"Android.mk",
&"""
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := main
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../SDL/include
LOCAL_SRC_FILES := {cfiles.join(" ")}
LOCAL_SHARED_LIBRARIES := SDL2
LOCAL_LDLIBS := -lGLESv1_CM -lGLESv2 -llog

include $(BUILD_SHARED_LIBRARY)
""")
  elif config.windowFormat == Webview:
    #---------------------------------------
    # Webview
    #---------------------------------------
    writeFile(activity_java_path, &"""
package {config.java_package_name};

import org.wiish.exampleapp.WiishActivity;

public class {activity_name} extends WiishActivity
{{
}}
    """)
    replaceInFile(projectDir/"app"/"src"/"main"/"AndroidManifest.xml", {
      "WiishActivity": activity_name,
    }.toTable)
    writeFile(projectDir/"app"/"jni"/"src"/"Android.mk",
&"""
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := main
LOCAL_SRC_FILES := {cfiles.join(" ")}
LOCAL_LDLIBS := -llog

include $(BUILD_SHARED_LIBRARY)
    """)
  
  debug &"Naming app ..."
  replaceInFile(projectDir/"app"/"src"/"main"/"res"/"values"/"strings.xml", {
    "<string name=\"app_name\">.*?</string>": &"""<string name="app_name">{config.name}</string>""",
  }.toTable)

  debug &"Creating icons ..."
  var iconSrcPath:string
  if config.icon == "":
    iconSrcPath = DATADIR()/"default.png"
  else:
    iconSrcPath = directory/config.icon
  iconSrcPath.resizePNG(projectDir/"app"/"src"/"main"/"res"/"mipmap-mdpi"/"ic_launcher.png", 48, 48)
  iconSrcPath.resizePNG(projectDir/"app"/"src"/"main"/"res"/"mipmap-hdpi"/"ic_launcher.png", 72, 72)
  iconSrcPath.resizePNG(projectDir/"app"/"src"/"main"/"res"/"mipmap-xhdpi"/"ic_launcher.png", 96, 96)
  iconSrcPath.resizePNG(projectDir/"app"/"src"/"main"/"res"/"mipmap-xxhdpi"/"ic_launcher.png", 144, 144)
  iconSrcPath.resizePNG(projectDir/"app"/"src"/"main"/"res"/"mipmap-xxxhdpi"/"ic_launcher.png", 192, 192)

  if srcResources.dirExists:
    debug &"Copying in resources ..."
    createDir(dstResources)
    copyDir(srcResources, dstResources)

  debug &"Building with gradle in {projectDir} ..."
  withDir(projectDir):
    # TODO: assembleRelease?
    let args = ["/bin/bash", "gradlew", "assembleDebug", "--console=plain"]
    debug args.join(" ")
    run(args)
  
  result = projectDir/"app"/"build"/"outputs"/"apk"/"debug"/"app-debug.apk"

proc runningDevices(): seq[string] {.inline.} = 
  ## List all currently running Android devices
  runoutput("adb", "devices").strip.splitLines[1..^1]

proc possibleDevices(): seq[string] =
  ## List all installed android devices
  let emulator_bin = findExe("emulator")
  return runoutput(emulator_bin, "-list-avds").strip.splitLines

proc doAndroidRun*(directory: string, verbose: bool = false) =
  ## Run the application in the Android emulator
  let
    configPath = directory/"wiish.toml"
    config = getAndroidConfig(parseConfig(configPath))

  let adb_bin = findExe("adb")
  if adb_bin == "":
    raise newException(CatchableError, "Could not find 'adb'.  Are the Android SDK tools in PATH?")
  
  let android_home = adb_bin.parentDir.parentDir
  debug &"Android SDK path = {android_home}"

  debug "Building app ..."
  let apkPath = doAndroidBuild(directory, config)

  debug "Opening emulator ..."
  let device_list = runningDevices()
  debug &"devices: {device_list.repr}"
  if device_list.len == 0:
    debug "No running devices. Let's start one..."
    let emulator_bin = findExe("emulator")
    let possible_avds = possibleDevices()
    debug &"Found {possible_avds.len} possible devices"
    if possible_avds.len == 0:
      raise newException(CatchableError, "No emulators installed. XXX provide instructions to get them installed.")
    let avd = possible_avds[0]
    debug &"Launching {avd} ..."
    
    var p = startProcess(command=emulator_bin,
      args = @["-avd", possible_avds[0], "-no-snapshot-save"], options = {poUsePath})
    # XXX it would maybe be nice to leave this running...
    debug "Waiting for device to boot ..."
    run("adb", "wait-for-local-device")
  
  debug &"Installing apk {apkPath} ..."
  run("adb", "install", "-r", "-t", apkPath)

  debug &"Watching logs ..."
  var logargs = @["logcat"]
  logargs.add(@["-T", "1"])
  if not verbose:
    logargs.add("-s")
    logargs.add(config.java_package_name)
    logargs.add("nim")
  var logp = startProcess(command="adb", args = logargs, options = {poUsePath, poParentStreams})

  let
    fullActivityName = config.fullActivityName()
    fullAppName = fullActivityName.split({'.'})[0..^2].join(".") & "/" & fullActivityName
  debug &"Starting app ({fullActivityName}) on device ..."
  debug fullAppName
  run("adb", "shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", fullAppName)

  discard logp.waitForExit()


proc checkDoctor*():seq[DoctorResult] =
  var cap:DoctorResult
  # emulator
  cap = DoctorResult(name: "android/emulator")
  if findExe("emulator") == "":
    cap.status = NotWorking
    cap.error = "Could not find 'emulator'"
    cap.fix = "Download the Android SDK and include sdk/emulator in the PATH"
  else:
    cap.status = Working
  result.add(cap)

  # adb
  cap = DoctorResult(name: "android/sdk-platform-tools")
  if findExe("adb") == "":
    cap.status = NotWorking
    cap.error = "Could not find 'adb'"
    cap.fix = "Download the Android SDK and include sdk/platform-tools in PATH"
  else:
    cap.status = Working
  result.add(cap)
  
  # devices
  cap = DoctorResult(name: "android/devices")
  try:
    let devices = possibleDevices()
    if devices.len == 0:
      cap.status = NotWorking
      cap.error = "No Android emulation devices found"
      cap.fix = "Use Android Studio to install a device. XXX need better instructions"
    else:
      cap.status = Working
  except:
    cap.status = NotWorking
    cap.error = "Could not find 'emulator'"
    cap.fix = "Fix android/emulator first"
  result.add(cap)
  

