import os
import strformat
import strutils
import tables
when defined(linux):
  import osproc
  import distros

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
import wiish/doctor

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
    ctx.logStartStep
    ctx.log "Linux builds not yet supported"
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

proc iosRunStep*(b: WiishWebviewPlugin, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview iOS Build
  case step
  of Compile:
    ctx.logStartStep()
    var
      nimFlags, linkerFlags, compilerFlags: seq[string]
    template linkAndCompile(flag:untyped) =
      linkerFlags.add(flag)
      compilerFlags.add(flag)
    nimFlags.add([
      "--os:macosx",
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
      "--out:" & ctx.executable_path,
      "--nimcache:nimcache",
      ])
    for flag in linkerFlags:
      nimFlags.add("--passL:" & flag)
    for flag in compilerFlags:
      nimFlags.add("--passC:" & flag)
    
    nimFlags.add(ctx.config.nimflags)

    ctx.log "Doing build ..."
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
  else:
    ctx.log "Not yet supported: ", $ctx.targetOS

proc checkDoctor*(): seq[DoctorResult] =
  when defined(linux):
    # TODO: make this work for other distors
    let packages = [
      ("gtk+-3.0", "libgtk-3-dev"),
      ("webkit2gtk-4.0", "libwebkit2gtk-4.0-dev"),
    ]
    for (name, installname) in packages:
      result.dr "webview", name:
        dr.targetOS = {Linux}
        if execCmdEx("pkg-config --cflags " & name).exitCode != 0:
          dr.status = NotWorking
          dr.error = &"Missing library {name}"
          dr.fix = "Maybe this will work:\l\l  "
          let cmd = foreignDepInstallCmd(installname)
          if cmd[1]:
            dr.fix.add "sudo "
          dr.fix.add cmd[0]
