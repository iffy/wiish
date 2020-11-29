import os; export os
import sequtils; export sequtils
import strformat; export strformat
import strutils; export strutils
import argparse; export argparse

import ./building/config
import ./building/buildutil; export buildutil
import ./building/build_macos

type
  WiishBuild* = object
    ## Object for standard Wiish build plugin

proc name*(b: WiishBuild): string = "WiishStd"

proc runStep*(b: WiishBuild, step: BuildStep, ctx: ref BuildContext) =
  if ctx.targetOS == Mac:
    macBuild(step, ctx)

var parser = newParser:
  option("--os", choices = (low(TargetOS)..high(TargetOS)).mapIt($it))
  option("-t", "--target", multiple = true, choices = (low(TargetFormat)..high(TargetFormat)).mapIt($it))

template build*[T](builders: T) =
  ## Perform a plugin-based Wiish build with the given plugins
  ## Provide plugins as a tuple.
  let opts = parser.parse(commandLineParams())
  if opts.help:
    echo parser.help
    quit(0)
  echo "[wiish] build starting..."
  var ctx: ref BuildContext
  new(ctx)
  ctx.projectPath = absolutePath(".")
  try:
    ctx.targetOS = parseEnum[TargetOS](opts.os)
  except:
    when defined(macosx):
      ctx.targetOS = Mac
    elif defined(windows):
      ctx.targetOS = Windows
    else:
      ctx.targetOS = Linux
  if opts.target.len == 0:
    ctx.targetFormats = @[defaultFormat]
  else:
    ctx.targetFormats = opts.target.mapIt(parseEnum[TargetFormat](it))
  
  let configPath = ctx.projectPath / "wiish.toml"
  ctx.config =
    case ctx.targetOS
    of Mac: getMacosConfig(configPath)
    of Android: getAndroidConfig(configPath)
    of Windows: getWindowsConfig(configPath)
    of Ios: getiOSConfig(configPath)
    of Linux: getLinuxConfig(configPath)
    of AutoDetectOS: getMyOSConfig(configPath)

  echo "[wiish] projectPath:   ", ctx.projectPath
  echo "[wiish] targetOS:      ", $ctx.targetOS
  echo "[wiish] targetFormats: ", $ctx.targetFormats
  echo "[wiish] config: ", $ctx.config
  for step in low(BuildStep)..high(BuildStep):
    echo &"[wiish] -- " & $step
    for key, builder in builders.fieldPairs:
      echo &"[wiish] ---- " & builder.name()
      builder.runStep(step, ctx)
  echo "[wiish] build complete"
