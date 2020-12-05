## This file is used from a project's local build file.  It's the
## entrypoint into wiish for that file.
import os; export os
import sequtils; export sequtils
import strformat; export strformat
import strutils; export strutils
import argparse; export argparse

import wiish/plugins/standard; export standard

import ./building/config
import ./building/buildutil; export buildutil

proc parseTargetOS*(x: string): TargetOS {.inline.} =
  parseEnum[TargetOS](x, AutoDetectOS)

proc parseTargetFormat*(x: string): TargetFormat {.inline.} =
  parseEnum[TargetFormat](x, targetAuto)

proc detectTargetOS*(targetFormat: TargetFormat): TargetOS =
  case targetFormat
  of targetRun, targetAuto:
    when defined(macosx):
      return Mac
    elif defined(windows):
      return Windows
    else:
      return Linux
  of targetMacDMG, targetMacApp:
    return Mac
  of targetIosApp:
    return Ios
  of targetAndroidApk:
    return Android
  of targetWinExe, targetWinInstaller:
    return Windows

proc detectTargetFormat*(targetOS: TargetOS): TargetFormat =
  case targetOS
  of Mac:
    return targetMacApp
  of Windows:
    return targetWinExe
  of Ios:
    return targetIosApp
  of IosSimulator:
    return targetRun
  of Android:
    return targetAndroidApk
  of Linux:
    raise ValueError.newException("Linux guessing of target format not supported yet")
  of MobileDev:
    return targetRun
  of AutoDetectOS:
    discard

template doBuildSteps*[T](ctx: ref BuildContext, builders: T) =
  ctx.log "build starting..."
  if ctx.targetOS == AutoDetectOS and ctx.targetFormat in {targetAuto, targetRun}:
    ctx.log "choosing targetOS..."
    ctx.targetOS = detectTargetOS(ctx.targetFormat)

  if ctx.targetFormat == targetAuto:
    ctx.log "choosing targetFormat..."
    ctx.targetFormat = detectTargetFormat(ctx.targetOS)
  
  if ctx.targetOS == AutoDetectOS:
    ctx.log "choosing targetOS..."
    ctx.targetOS = detectTargetOS(ctx.targetFormat)

  let configPath = ctx.projectPath / "wiish.toml"
  ctx.config =
    case ctx.targetOS
    of Mac: getMacosConfig(configPath)
    of Android: getAndroidConfig(configPath)
    of Windows: getWindowsConfig(configPath)
    of Ios,IosSimulator: getiOSConfig(configPath)
    of Linux: getLinuxConfig(configPath)
    of AutoDetectOS: getMyOSConfig(configPath)
    of MobileDev: getMobileDevConfig(configPath)

  ctx.log "projectPath:   ", ctx.projectPath
  ctx.log "targetOS:      ", $ctx.targetOS
  ctx.log "targetFormat:  ", $ctx.targetFormat
  var viable = ctx.targetOS.viableTargets()
  if ctx.targetFormat notin viable:
    stderr.writeLine &"ERROR: Unsupported targetOS/targetFormat combination. Expected targetFormat to be one of " & $viable
    quit 1
  ctx.log "verbosity:     ", $ctx.verbose
  ctx.log "config: ", $ctx.config[]
  for step in low(BuildStep)..high(BuildStep):
    if step == Run and ctx.targetFormat != targetRun:
      continue
    ctx.currentStep = step
    for key, builder in builders.fieldPairs:
      ctx.currentPlugin = builder.name()
      builder.runStep(step, ctx)
  stderr.writeLine "[wiish] build complete"

template build*[T](builders: T) =
  ## Perform a plugin-based Wiish build with the given plugins
  ## Provide plugins as a tuple.
  var parser = newParser:
    command "build":
      option("--os", choices = (low(TargetOS)..high(TargetOS)).mapIt($it))
      option("-t", "--target", choices = (low(TargetFormat)..high(TargetFormat)).mapIt($it))
      flag("--verbose")
      run:
        var ctx = newBuildContext()
        ctx.projectPath = "."
        ctx.targetOS = parseTargetOS(opts.os)
        ctx.targetFormat = parseTargetFormat(opts.target)
        ctx.verbose = opts.verbose
        doBuildSteps(ctx, builders)
    command "run":
      option("--os", choices = (low(TargetOS)..high(TargetOS)).mapIt($it))
      flag("--verbose")
      run:
        var ctx = newBuildContext()
        ctx.projectPath = "."
        ctx.targetOS = parseTargetOS(opts.os)
        ctx.targetFormat = targetRun
        ctx.verbose = opts.verbose
        doBuildSteps(ctx, builders)
    command "doctor":
      run:
        raise ValueError.newException("doctor not implemented yet")
  parser.run()
