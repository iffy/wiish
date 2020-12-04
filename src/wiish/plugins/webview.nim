import os
import strformat
import strutils

import wiish/building/buildutil
import wiish/building/config

import wiish/plugins/standard/build_ios

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

proc runStep*(b: WiishWebviewBuild, step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Webview Build
  case ctx.targetOS
  of Mac:
    b.macRunStep(step, ctx)
  of Ios,IosSimulator:
    b.iosRunStep(step, ctx)
  else:
    ctx.log "Unable to compile for: ", $ctx.targetOS

