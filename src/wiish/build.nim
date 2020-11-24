import os
import sequtils
import strformat
import strutils

import ./building/config
import ./building/buildutil; export buildutil
import ./building/build_macos

proc wiishStdBuild*(step: BuildStep, ctx: ref BuildContext) =
  if ctx.targetOS == Mac:
    macBuild(step, ctx)

proc build*(builders: seq[buildProc]) =
  ## Perform a plugin-based Wiish build
  echo "[wiish] build starting..."
  var ctx: ref BuildContext
  new(ctx)
  ctx.projectPath = absolutePath(".")
  try:
    ctx.targetOS = parseEnum[TargetOS](getEnv("WIISH_TARGET_OS"))
  except:
    raise ValueError.newException("Error parsing WIISH_TARGET_OS: " & getEnv("WIISH_TARGET_OS"))
  try:
    let formats = getEnv("WIISH_TARGET_FORMATS")
    if formats == "":
      ctx.targetFormats = @[defaultFormat]
    else:
      ctx.targetFormats = formats.split(",").mapIt(parseEnum[TargetFormat](it))
  except:
    raise ValueError.newException("Error parsing WIISH_TARGET_FORMATS: " & getEnv("WIISH_TARGET_FORMATS"))
  
  let configPath = ctx.projectPath / "wiish.toml"
  case ctx.targetOS
  of Mac: ctx.config = getMacosConfig(configPath)
  of Android: ctx.config = getAndroidConfig(configPath)
  of Windows: ctx.config = getWindowsConfig(configPath)
  of Ios: ctx.config = getiOSConfig(configPath)
  of Linux: ctx.config = getLinuxConfig(configPath)
  of AutoDetectOS: ctx.config = getMyOSConfig(configPath)

  echo "[wiish] projectPath:   ", ctx.projectPath
  echo "[wiish] targetOS:      ", $ctx.targetOS
  echo "[wiish] targetFormats: ", $ctx.targetFormats
  echo "[wiish] config: ", $ctx.config
  for step in low(BuildStep)..high(BuildStep):
    echo &"[wiish] ----- {step}"
    for builder in builders:
      builder(step, ctx)
  echo "[wiish] build complete"
