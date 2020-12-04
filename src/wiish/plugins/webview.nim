import os
import osproc
import strformat
import strutils
import tables

import wiish/building/buildutil
import wiish/building/config

import wiish/plugins/standard/build_ios
import wiish/plugins/standard/build_android

type
  WiishWebviewBuild* = ref object
    ## Webview build plugin

proc name*(b: WiishWebviewBuild): string = "WiishWebview"

proc macRunStep*(b: WiishWebviewBuild, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview macOS Build
  case step
  of Compile:
    ctx.logStartStep()
    # Compile Contents/MacOS/bin
    var args = @[
      "nim",
      "c",
      "-d:release",
      "--gc:orc",
      &"-d:appName={ctx.config.name}",
    ]
    args.add(ctx.config.nimflags)
    args.add(&"-o:{ctx.executable_path}")
    args.add(ctx.main_nim)
    sh(args)
  else:
    discard

proc iosRunStep*(b: WiishWebviewBuild, step: BuildStep, ctx: ref BuildContext) =
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

proc androidRunStep*(b: WiishWebviewBuild, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview Android build
  case step
  of Setup:
    ctx.logStartStep
  of PreCompile:
    ctx.logStartStep
    if not ctx.build_dir.dirExists():
      ctx.log &"Copying Android template project to {ctx.build_dir}"
      createDir(ctx.build_dir)
      copyDirWithPermissions(DATADIR()/"android-webview", ctx.build_dir)

      # build.gradle
      replaceInFile(ctx.build_dir/"app"/"build.gradle", {
        "org.wiish.exampleapp": ctx.config.java_package_name,
      }.toTable)

      # AndroidManifest.xml
      replaceInFile(ctx.build_dir/"app"/"src"/"main"/"AndroidManifest.xml", {
        "org.wiish.exampleapp": ctx.config.java_package_name,
      }.toTable)
  of Compile:
    ctx.logStartStep
    proc buildFor(android_abi:string, cpu:string) =
      let nimcachedir = ctx.build_dir/"app"/"jni"/"src"/android_abi
      if nimcachedir.dirExists:
        nimcachedir.removeDir()
      var nimFlags:seq[string]
      nimFlags.add(@["nim", "c"])
      nimFlags.add(ctx.config.nimflags)
      nimFlags.add(@[
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
        &"-d:appJavaPackageName={ctx.config.java_package_name}",
        "--nimcache:" & nimcachedir,
        ctx.main_nim,
      ])
      ctx.log nimFlags.join(" ")
      sh(nimFlags)
      
      let
        nimbase_dst = ctx.build_dir/"app"/"jni"/"src"/android_abi/"nimbase.h"
        nimversion = execCmdEx("nim --version").output.split(" ")[3]
        nimminor = nimversion.rsplit(".", 1)[0]
      ctx.log &"Writing {nimbase_dst} for Nim version {nimminor} ..."
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
  
    ctx.log "Create Activity ..."
    let
      activity_name = ctx.activityName()
      activity_java_path = ctx.build_dir/"app"/"src"/"main"/"java"/ctx.config.java_package_name.replace(".", "/")/activity_name&".java"
    activity_java_path.parentDir.createDir()
    
    var cfiles : seq[string]
    ctx.log "Listing c files ..."
    for item in walkDir(ctx.build_dir/"app"/"jni"/"src"/"x86"):
      if item.kind == pcFile and item.path.endsWith(".c"):
        cfiles.add("$(TARGET_ARCH_ABI)"/(&"{item.path.extractFilename}"))
    
    replaceInFile(ctx.build_dir/"app"/"build.gradle", {
      "abiFilters.*?\n": "abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'\n",
    }.toTable)

    #---------------------------------------
    # Webview
    #---------------------------------------
    ctx.log &"Writing {activity_java_path}"
    writeFile(activity_java_path, &"""
  package {ctx.config.java_package_name};

  import org.wiish.exampleapp.WiishActivity;

  public class {activity_name} extends WiishActivity
  {{
  }}
    """)
    replaceInFile(ctx.build_dir/"app"/"src"/"main"/"AndroidManifest.xml", {
      "WiishActivity": activity_name,
    }.toTable)
    writeFile(ctx.build_dir/"app"/"jni"/"src"/"Android.mk",
  &"""
  LOCAL_PATH := $(call my-dir)

  include $(CLEAR_VARS)
  LOCAL_MODULE := main
  LOCAL_SRC_FILES := {cfiles.join(" ")}
  LOCAL_LDLIBS := -llog

  include $(BUILD_SHARED_LIBRARY)
    """)
    
    ctx.log &"Naming app ..."
    replaceInFile(ctx.build_dir/"app"/"src"/"main"/"res"/"values"/"strings.xml", {
      "<string name=\"app_name\">.*?</string>": &"""<string name="app_name">{ctx.config.name}</string>""",
    }.toTable)
  else:
    discard

proc runStep*(b: WiishWebviewBuild, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview Build
  case ctx.targetOS
  of Mac:
    b.macRunStep(step, ctx)
  of Ios,IosSimulator:
    b.iosRunStep(step, ctx)
  of Android:
    b.androidRunStep(step, ctx)
  else:
    ctx.log "Unable to compile for: ", $ctx.targetOS

