import os
import strformat
import strutils
import tables

#-------------------------------------------------------------------
# Importing for app
#-------------------------------------------------------------------
import wiish/baseapp
import wiish/common; export common

type
  IWebviewWindow* = concept win
    ## This is the interface required for a webview window
    win.onReady is EventSource[bool]
    win.onMessage is EventSource[string]
  
  IWebviewApp* = concept app
    ## These are the things needed for a webview desktop app
    # app is IBaseApp
    newWebviewApp() is ref typeof app
    app.start(url = string)
    app.start()
    app.life is EventSource[LifeEvent]
    app.newWindow(url = string, title = string) is IWebviewWindow
    app.getWindow(int) is IWebviewWindow

when wiish_ios:
  import ./webview/webview_ios; export webview_ios
elif wiish_android:
  import ./webview/webview_android; export webview_android
else:
  import ./webview/desktop; export desktop

#-------------------------------------------------------------------
# Building
#-------------------------------------------------------------------
import wiish/building/buildutil
import wiish/building/config

import wiish/plugins/standard/common as stdcommon
import wiish/plugins/standard/build_ios
import wiish/plugins/standard/build_android

const datadir = currentSourcePath.parentDir / "webview" / "data"

type
  WiishWebviewPlugin* = ref object
    ## Webview build plugin

proc name*(b: WiishWebviewPlugin): string = "WiishWebview"

proc desktopRun*(b: WiishWebviewPlugin, ctx: ref BuildContext) =
  if ctx.targetFormat in {targetRun}:
    ctx.logStartStep()
    var args = @[findExe"nim", "c"]
    args.add ctx.nim_flags
    args.add ctx.nim_run_flags
    args.add "-r"
    args.add ctx.main_nim
    echo args.join(" ")
    sh args

proc macRunStep*(b: WiishWebviewPlugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview macOS Build
  case step
  of Compile:
    if ctx.targetFormat in {targetMacApp, targetMacDMG}:
      ctx.logStartStep()
      # Compile Contents/MacOS/bin
      var args = @[
        "nim",
        "c",
        "-d:release",
        &"-d:appName={ctx.config.name}",
      ]
      args.add(ctx.nim_flags)
      args.add(&"-o:{ctx.executable_path}")
      args.add(ctx.main_nim)
      sh(args)
  of Run:
    b.desktopRun(ctx)
  else:
    discard

proc linuxRunStep*(b: WiishWebviewPlugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview Linux Build
  case step
  of Compile:
    if ctx.targetFormat != targetRun:
      raise ValueError.newException("Linux SDL2 building not supported yet")
  of Run:
    b.desktopRun(ctx)
  else:
    discard

proc windowsRunStep*(b: WiishWebviewPlugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview Windows Build
  case step
  of Compile:
    if ctx.targetFormat != targetRun:
      raise ValueError.newException("Windows SDL2 building not supported yet")
  of Run:
    b.desktopRun(ctx)
  else:
    discard

proc mobiledevRunStep*(b: WiishWebviewPlugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview mobile dev run
  case step
  of Run:
    b.desktopRun(ctx)
  else:
    discard

proc output_lib(ctx: ref BuildContext): string =
  ## Path to the static library for the iOS build.
  ctx.xcode_project_root / "wiishboilerplate" / "app.a"

proc iosRunStep*(b: WiishWebviewPlugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview iOS Build
  case step
  of Setup:
    ctx.logStartStep
    ctx.xcode_project_root = ctx.build_dir / "xc"
    ctx.xcode_build_scheme = ctx.config.name
    if not ctx.xcode_project_root.dirExists():
      ctx.log &"Copying iOS template project to {ctx.xcode_project_root}"
      createDir(ctx.xcode_project_root)
      copyDirWithPermissions(datadir / "ios-webview", ctx.xcode_project_root)
    else:
      ctx.log &"Xcode project already exists: {ctx.xcode_project_root}"
    
    # clean up old .a file
    if ctx.output_lib.fileExists():
      ctx.log "Cleaning up old " & ctx.output_lib
      removeFile(ctx.output_lib)
  of Compile:
    ctx.logStartStep()
    var
      nimFlags, linkerFlags, compilerFlags: seq[string]
    template linkAndCompile(flag:untyped) =
      linkerFlags.add(flag)
      compilerFlags.add(flag)
    nimFlags.add([
      "--os:ios",
      "--app:staticlib",
      "-d:ios",
      "-d:iPhone",
      &"-d:appBundleIdentifier={ctx.config.bundle_identifier}",
    ])
    if ctx.simulator:
      nimFlags.add([
        "--cpu:amd64",
        "-d:simulator",
      ])
    else:
      nimFlags.add([
        "--cpu:arm64",
      ])
      linkAndCompile(&"-arch arm64")
    
    if ctx.simulator:
      linkAndCompile(&"-mios-simulator-version-min={ctx.ios_sdk_version}")
    else:
      linkAndCompile(&"-mios-version-min={ctx.ios_sdk_version}")
    linkAndCompile(["-isysroot", ctx.ios_sdk_path])
    
    nimFlags.add([
      "--warning[LockLevel]:off",
      "--verbosity:0",
      "--hint[Pattern]:off",
      "--parallelBuild:0",
      "--threads:on",
      "--tlsEmulation:off",
      "--out:" & ctx.output_lib,
      ])
    for flag in linkerFlags:
      nimFlags.add("--passL:" & flag)
    for flag in compilerFlags:
      nimFlags.add("--passC:" & flag)
    
    nimFlags.add(ctx.config.nimflags)

    ctx.log "Doing compile ..."
    var args = @["nim", "objc"]
    args.add(nimFlags)
    args.add(ctx.main_nim)
    ctx.log args.join(" ")
    sh(args)
  else:
    discard

proc androidRunStep*(b: WiishWebviewPlugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview Android build
  case step
  of Setup:
    ctx.logStartStep
    if not ctx.build_dir.dirExists():
      ctx.log &"Copying Android template project to {ctx.build_dir}"
      createDir(ctx.build_dir)
      copyDirWithPermissions(datadir / "android-webview", ctx.build_dir)

      # build.gradle
      replaceInFile(ctx.build_dir/"app"/"build.gradle", {
        "org.wiish.exampleapp": ctx.config.java_package_name,
      }.toTable)

      # AndroidManifest.xml
      replaceInFile(ctx.build_dir/"app"/"src"/"main"/"AndroidManifest.xml", {
        "org.wiish.exampleapp": ctx.config.java_package_name,
      }.toTable)
  of PreBuild:
    ctx.logStartStep
    ctx.log &"Writing {ctx.activityJavaPath()}"
    writeFile(ctx.activityJavaPath, &"""
package {ctx.config.java_package_name};

import org.wiish.exampleapp.WiishActivity;

public class {ctx.activityName()} extends WiishActivity
{{
}}
    """)
    replaceInFile(ctx.build_dir/"app"/"src"/"main"/"AndroidManifest.xml", {
      "WiishActivity": ctx.activityName(),
    }.toTable)
    writeFile(ctx.build_dir/"app"/"jni"/"src"/"Android.mk",
  &"""
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := main
LOCAL_SRC_FILES := {ctx.getCFiles().join(" ")}
LOCAL_LDLIBS := -llog
# TODO: Make it more straightforward to modify these values in other plugins
#LOCAL_SHARED_LIBRARIES
#LOCAL_STATIC_LIBRARIES
#LOCAL_CFLAGS

include $(BUILD_SHARED_LIBRARY)
    """)
  else:
    discard

proc runStep*(b: WiishWebviewPlugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview Build
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

