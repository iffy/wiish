## Import this module to get the build template
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

proc parseTargetFormats*(x: seq[string]): seq[TargetFormat] {.inline.} =
  x.mapIt(parseEnum[TargetFormat](it, targetAuto))

template doBuildSteps*[T](ctx: ref BuildContext, builders: T) =
  ctx.log "build starting..."
  if ctx.targetOS == AutoDetectOS:
    ctx.log "auto-detecting target OS"
    when defined(macosx):
      ctx.targetOS = Mac
    elif defined(windows):
      ctx.targetOS = Windows
    else:
      ctx.targetOS = Linux

  if ctx.targetFormats.len == 0 or ctx.targetFormats == @[targetAuto]:
    ctx.log "default target formats"
    case ctx.targetOS
    of Mac:
      ctx.targetFormats = @[targetMacApp]
    of Windows:
      ctx.targetFormats = @[targetWinExe]
    of Ios,IosSimulator:
      ctx.targetFormats = @[targetIosApp]
    of Android:
      ctx.targetFormats = @[targetAndroidApk]
    of Linux:
      raise ValueError.newException("Linux guessing of target format not supported yet")
    of AutoDetectOS:
      discard
  
  let configPath = ctx.projectPath / "wiish.toml"
  ctx.config =
    case ctx.targetOS
    of Mac: getMacosConfig(configPath)
    of Android: getAndroidConfig(configPath)
    of Windows: getWindowsConfig(configPath)
    of Ios,IosSimulator: getiOSConfig(configPath)
    of Linux: getLinuxConfig(configPath)
    of AutoDetectOS: getMyOSConfig(configPath)

  ctx.log "projectPath:   ", ctx.projectPath
  ctx.log "targetOS:      ", $ctx.targetOS
  ctx.log "targetFormats: ", $ctx.targetFormats
  ctx.log "config: ", $ctx.config[]
  for step in low(BuildStep)..high(BuildStep):
    if step == Run and targetRun notin ctx.targetFormats:
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
      option("-t", "--target", multiple = true, choices = (low(TargetFormat)..high(TargetFormat)).mapIt($it))
      run:
        var ctx = newBuildContext()
        ctx.projectPath = "."
        ctx.targetOS = parseTargetOS(opts.os)
        ctx.targetFormats = parseTargetFormats(opts.target)
        doBuildSteps(ctx, builders)
    command "run":
      option("--os", choices = (low(TargetOS)..high(TargetOS)).mapIt($it))
      run:
        var ctx = newBuildContext()
        ctx.projectPath = "."
        ctx.targetOS = parseTargetOS(opts.os)
        ctx.targetFormats = @[targetRun]
        doBuildSteps(ctx, builders)
  parser.run()
