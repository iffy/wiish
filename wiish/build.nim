## This file is used from a project's local build file.  It's the
## entrypoint into wiish for that file.
import os; export os
import sequtils; export sequtils
import strformat; export strformat
import strutils; export strutils
import argparse; export argparse

import wiish/plugins/standard; export standard

import ./building/config; export config
import ./building/buildutil; export buildutil

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
  of targetIosApp, targetIosIpa:
    return Ios
  of targetAndroidApk:
    return Android
  of targetWinExe, targetWinInstaller:
    return Windows
  of targetLinuxBin:
    return Linux

proc detectTargetFormat*(targetOS: TargetOS): TargetFormat =
  case targetOS
  of Mac:
    return targetMacApp
  of Windows:
    return targetWinExe
  of Ios:
    return targetIosApp
  of IosSimulator:
    return targetIosApp
  of Android:
    return targetAndroidApk
  of Linux:
    return targetLinuxBin
  of MobileDev:
    return targetRun
  of AutoDetectOS:
    discard

template doBuildSteps*[T](ctx: ref BuildContext, builders: T, steps: set[BuildStep] = {}) =
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

  ctx.log "projectPath:   ", ctx.projectPath
  ctx.log "targetOS:      ", $ctx.targetOS
  ctx.log "targetFormat:  ", $ctx.targetFormat
  var viable = ctx.targetOS.viableTargets()
  if ctx.targetFormat notin viable:
    stderr.writeLine &"ERROR: Unsupported targetOS/targetFormat combination. Expected targetFormat to be one of " & $viable
    quit 1
  ctx.log "verbosity:     ", $ctx.verbose
  # ctx.log "config: ", $ctx.config[]
  for step in low(BuildStep)..high(BuildStep):
    if steps.len > 0 and step notin steps:
      continue
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
  proc parseSteps(inp: seq[string]): set[BuildStep] =
    for x in inp:
      result.incl parseEnum[BuildStep](x, Setup)

  var parser = newParser:
    command "step", "Low level":
      option("--os", choices = (low(TargetOS)..high(TargetOS)).mapIt($it))
      option("-t", "--target", choices = (low(TargetFormat)..high(TargetFormat)).mapIt($it))
      flag("--verbose")
      flag("--release", help = "Build a release version (rather than debug)")
      arg("steps", nargs = -1, help = "Step(s) to run. [" & toSeq(low(BuildStep)..high(BuildStep)).join(", ") & "]")
      run:
        var ctx = newBuildContext()
        ctx.projectPath = "."
        ctx.targetOS = parseTargetOS(opts.os)
        ctx.targetFormat = parseTargetFormat(opts.target)
        ctx.releaseBuild = opts.release
        ctx.verbose = opts.verbose
        let steps = parseSteps(opts.steps)
        doBuildSteps(ctx, builders, steps)
    command "build", "High level":
      option("--os", choices = (low(TargetOS)..high(TargetOS)).mapIt($it))
      option("-t", "--target", choices = (low(TargetFormat)..high(TargetFormat)).mapIt($it))
      flag("--verbose")
      flag("--release", help = "Build a release version (rather than debug)")
      run:
        var ctx = newBuildContext()
        ctx.projectPath = "."
        ctx.targetOS = parseTargetOS(opts.os)
        ctx.targetFormat = parseTargetFormat(opts.target)
        ctx.releaseBuild = opts.release
        ctx.verbose = opts.verbose
        doBuildSteps(ctx, builders)
    command "run", "High level":
      option("--os", choices = (low(TargetOS)..high(TargetOS)).mapIt($it))
      flag("--verbose")
      flag("--release", help = "Build a release version (rather than debug)")
      run:
        var ctx = newBuildContext()
        ctx.projectPath = "."
        ctx.targetOS = parseTargetOS(opts.os)
        ctx.targetFormat = targetRun
        ctx.releaseBuild = opts.release
        ctx.verbose = opts.verbose
        doBuildSteps(ctx, builders)
    command "doctor", "High level":
      run:
        raise ValueError.newException("doctor not implemented yet")
    
  parser.run()
