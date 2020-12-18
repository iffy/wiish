import os
import osproc
import strformat
import strutils
import tables

import wiish/building/buildutil
import wiish/plugins/standard/build_android

const datadir = currentSourcePath.parentDir / "sdl2" / "data"

type
  WiishSDL2Plugin* = ref object
    ## SDL2 plugin

proc name*(b: WiishSDL2Plugin): string {.inline.} = "WiishSDL2"


proc desktopRun*(b: WiishSDL2Plugin, ctx: ref BuildContext) =
  if ctx.targetFormat in {targetRun}:
    ctx.logStartStep()
    var args = @[findExe"nim", "c"]
    args.add ctx.nim_flags
    args.add ctx.nim_run_flags
    args.add "-r"
    args.add ctx.main_nim
    echo args.join(" ")
    sh args


#-------------------------------------------------------------
# macOS
#-------------------------------------------------------------
proc macRunStep*(b: WiishSDL2Plugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish SDL2 macOS Build
  case step
  of Compile:
    if ctx.targetFormat in {targetMacApp, targetMacDMG}:
      ctx.logStartStep
      # Compile Contents/MacOS/bin
      var args = @[
        "nim",
        "c",
        "-d:release",
        &"-d:appName={ctx.config.name}",
      ]
      args.add(ctx.config.nimflags)
      args.add(&"-o:{ctx.executable_path}")
      args.add(ctx.main_nim)
      sh(args)
  of Run:
    b.desktopRun(ctx)
  else:
    discard

#-------------------------------------------------------------
# Linux
#-------------------------------------------------------------
proc linuxRunStep*(b: WiishSDL2Plugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish SDL2 Linux Build
  case step
  of Compile:
    if ctx.targetFormat != targetRun:
      raise ValueError.newException("Linux SDL2 building not supported yet")
  of Run:
    b.desktopRun(ctx)
  else:
    discard

#-------------------------------------------------------------
# Windows
#-------------------------------------------------------------
proc windowsRunStep*(b: WiishSDL2Plugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish SDL2 Windows Build
  case step
  of Compile:
    if ctx.targetFormat != targetRun:
      raise ValueError.newException("Windows SDL2 building not supported yet")
  of Run:
    b.desktopRun(ctx)
  else:
    discard

#-------------------------------------------------------------
# iOS
#-------------------------------------------------------------
proc iosBuildSDLLib(ctx: ref BuildContext, lib = ""): string =
  ## Find the path to the appropriate SDL.a library, compiling it
  ## first if necessary
  var
    libname: string
    platform = if ctx.simulator: "iphonesimulator" else: "iphoneos"
    xcodeProjDir: string
    xcodeProjFile: string
  case lib
  of "":
    libname = "libSDL2.a"
    xcodeProjDir = datadir / "SDL/Xcode-iOS/SDL"
    xcodeProjFile = xcodeProjDir / "SDL.xcodeproj"
  of "ttf":
    libname = "libSDL2_ttf.a"
    xcodeProjDir = datadir / "SDL_TTF/Xcode-iOS"
    xcodeProjFile = xcodeProjDir / "SDL_ttf.xcodeproj"
  else:
    raise ValueError.newException("Unknown SDL2 library name: " & lib)
  
  result = xcodeProjDir / "build/Release-" & platform / libname
  if not fileExists(result):
    ctx.log &"Building {result.extractFilename}..."
    var args = @[
      "xcodebuild",
      "-project", xcodeProjFile,
      "-configuration", "Release",
      "-sdk", platform & ctx.ios_sdk_version,
      "SYMROOT=build",
    ]
    if ctx.simulator:
      args.add("ARCHS=i386 x86_64")
    else:
      args.add("ARCHS=arm64 armv7")
    sh(args)
  else:
    ctx.log &"Using existing {result.extractFilename}"
  
  if not fileExists(result):
    raise newException(CatchableError, "Failed to build libSDL2.a")

proc iosRunStep*(b: WiishSDL2Plugin, step: BuildStep, ctx: ref BuildContext) =
  case step
  of Compile:
    ctx.logStartStep
    var
      nimflags: seq[string]
      linkerFlags: seq[string]
      compilerFlags: seq[string]

    ctx.log "Obtaining SDL2 library ..."
    let libsdl2_a = ctx.iosBuildSDLLib()
    ctx.log "Obtaining SDL2_ttf library ..."
    let libsdl2_ttf_a = ctx.iosBuildSDLLib("ttf")

    template linkAndCompile(flag:untyped) =
      linkerFlags.add(flag)
      compilerFlags.add(flag)
    
    nimFlags.add(@[
      "--noMain:on",
      "--os:macosx",
      "-d:ios",
      "-d:iPhone",
      &"-d:appBundleIdentifier={ctx.config.bundle_identifier}",
      "--dynlibOverride:SDL2",
      "--dynlibOverride:SDL2_ttf",
    ])
    if ctx.simulator:
      nimFlags.add(@[
        "--cpu:amd64",
        "-d:simulator",
      ])
    else:
      nimFlags.add(@[
        "--cpu:arm64",
      ])
      linkAndCompile(&"-arch arm64")
    
    if ctx.simulator:
      linkAndCompile(&"-mios-simulator-version-min={ctx.ios_sdk_version}")
    else:
      linkAndCompile(&"-mios-version-min={ctx.ios_sdk_version}")
    linkerFlags.add(@[
      "-fobjc-link-runtime",
      "-L", libsdl2_a.parentDir,
      "-L", libsdl2_ttf_a.parentDir,
      "-lSDL2",
      "-lSDL2_ttf",
    ])
    linkAndCompile(@["-isysroot", ctx.ios_sdk_path])
    nimFlags.add(@["--threads:on"])
    nimFlags.add(@[
      "--warning[LockLevel]:off",
      "--verbosity:0",
      "--hint[Pattern]:off",
      "--parallelBuild:0",
      "--threads:on",
      "--tlsEmulation:off",
      "--out:" & ctx.executable_path,
      "--nimcache:nimcache",
    ])
    for flag in linkerFlags:
      nimFlags.add("--passL:" & flag)
    for flag in compilerFlags:
      nimFlags.add("--passC:" & flag)
    
    nimFlags.add(ctx.nim_flags)

    ctx.log "Doing build ..."
    var args = @["nim", "objc"]
    args.add(nimFlags)
    args.add(ctx.main_nim)
    ctx.log args.join(" ")
    sh(args)
  else:
    discard

#-------------------------------------------------------------
# Android
#-------------------------------------------------------------
proc androidRunStep*(b: WiishSDL2Plugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish SDL2 Android Build
  case step
  of Setup:
    ctx.logStartStep
    if not ctx.build_dir.dirExists():
      ctx.log &"Copying SDL android project to {ctx.build_dir}"
      let sdlSrc = datadir / "SDL"
      createDir(ctx.build_dir)
      copyDirWithPermissions(sdlSrc/"android-project", ctx.build_dir)

      # Copy in SDL source
      copyDirWithPermissions(sdlSrc/"src", ctx.build_dir/"app"/"jni"/"SDL"/"src")
      copyDirWithPermissions(sdlSrc/"include", ctx.build_dir/"app"/"jni"/"SDL"/"include")
      let android_mk = ctx.build_dir/"app"/"jni"/"SDL"/"Android.mk"
      copyFile(sdlSrc/"Android.mk", android_mk)

      # build.gradle
      replaceInFile(ctx.build_dir/"app"/"build.gradle", {
        "org.libsdl.app": ctx.config.java_package_name,
      }.toTable)

      # AndroidManifest.xml
      replaceInFile(ctx.build_dir/"app"/"src"/"main"/"AndroidManifest.xml", {
        "org.libsdl.app": ctx.config.java_package_name,
      }.toTable)
  of PreBuild:
    ctx.logStartStep
    ctx.log &"Writing {ctx.activityJavaPath}"
    writeFile(ctx.activityJavaPath(), &"""
package {ctx.config.java_package_name};

import org.libsdl.app.SDLActivity;

public class {ctx.activityName()} extends SDLActivity
{{
}}
""")
    replaceInFile(ctx.build_dir/"app"/"src"/"main"/"AndroidManifest.xml", {
      "SDLActivity": ctx.activityName(),
    }.toTable)
    writeFile(ctx.build_dir/"app"/"jni"/"src"/"Android.mk",
&"""
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := main
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../SDL/include
LOCAL_SRC_FILES := {ctx.getCFiles().join(" ")}
LOCAL_SHARED_LIBRARIES := SDL2
LOCAL_LDLIBS := -lGLESv1_CM -lGLESv2 -llog

include $(BUILD_SHARED_LIBRARY)
""")
  else:
    discard

#-------------------------------------------------------------
# MobileDev
#-------------------------------------------------------------
proc mobiledevRunStep*(b: WiishSDL2Plugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish SDL mobiledev run
  case step
  of Run:
    b.desktopRun(ctx)
  else:
    discard

#-------------------------------------------------------------
# General
#-------------------------------------------------------------

proc runStep*(b: WiishSDL2Plugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish SDL2 Build
  case ctx.targetOS
  of Mac:
    b.macRunStep(step, ctx)
  of Ios,IosSimulator:
    b.iosRunStep(step, ctx)
  of Android:
    b.androidRunStep(step, ctx)
  of MobileDev:
    b.mobiledevRunStep(step, ctx)
  of Linux:
    b.linuxRunStep(step, ctx)
  of Windows:
    b.windowsRunStep(step, ctx)
  else:
    raise ValueError.newException("Not yet supported: " & $ctx.targetOS)

