import os
import osproc
import strutils
import logging
import tables
import terminal
import ./config

type
  TargetOS* = enum
    AutoDetectOS = "auto"
    Mac = "mac"
    Ios = "ios"
    IosSimulator = "ios-simulator"
    Android = "android"
    Windows = "windows"
    Linux = "linux"
  
  TargetFormat* = enum
    targetAuto = "auto"
    targetRun = "run"
    targetMacApp = "app"
    targetMacDMG = "dmg"
    targetWinExe = "exe"
    targetWinInstaller = "win-installer"
    targetIosApp = "ios-app"
  
  BuildContext* = object
    ## The context for all builds
    projectPath*: string
    targetOS*: TargetOS
    targetFormats*: seq[TargetFormat]
    config*: WiishConfig
    currentStep*: BuildStep
    currentPlugin*: string
    pluginData: TableRef[string, pointer]
    # data that is set during the build
    build_dir*: string
      ## Directory where build output goes
    executable_path*: string
      ## For builds that produce an executable, this is the path
      ## to that executable
    ios_sdk_version*: string

  BuildStep* = enum
    ## List of steps that are executed during a build
    Setup

    PreCompile
    Compile
    PostCompile

    PreBuild
    Build
    PostBuild

    PrePackage
    Package
    PostPackage

    PreSign
    Sign
    PostSign

    PreNotarize
    Notarize
    PostNotarize

    Run
  
  BuildPlugin* = concept p
    p.name() is string
    p.runStep(BuildStep, ref BuildContext)

type
  DoctorStatus* = enum
    NotWorking,
    Working,
  DoctorResult* = object
    name*: string
    status*: DoctorStatus
    error*: string
    fix*: string

const
  NIMBASE_1_0_X* = slurp"data/nimbase-1.0.x.h"
  NIMBASE_1_2_X* = slurp"data/nimbase-1.2.x.h"
  NIMBASE_1_4_x* = slurp"data/nimbase-1.4.x.h"


template withDir*(dir: string, body: untyped): untyped =
  ## Execute a block of code within another directory.
  let origDir = getCurrentDir()
  setCurrentDir(dir)
  body
  setCurrentDir(origDir)

proc sh*(args:varargs[string, `$`]) =
  ## Run a process, failing the program if it fails
  var p = startProcess(command = args[0],
    args = args[1..^1],
    options = {poUsePath, poParentStreams})
  if p.waitForExit() != 0:
    raise newException(CatchableError, "Error running process")

proc shoutput*(args:varargs[string, `$`]):string =
  ## Run a process and return the output as a string
  result = execProcess(command = args[0],
    args = args[1..^1],
    options = {poUsePath})

proc logprefix(ctx: ref BuildContext): string {.inline.} =
  "[wiish] " & $ctx[].currentStep & "/" & ctx[].currentPlugin & " "

proc log*(ctx: ref BuildContext, msg: varargs[string]) =
  stderr.writeLine ctx.logprefix & msg.join("")

proc logStartStep*(ctx: ref BuildContext) =
  styledWriteLine(stderr, fgCyan, ctx.logprefix, "start", resetStyle)

proc newBuildContext*(): ref BuildContext =
  new(result)
  result.pluginData = newTable[string,pointer]()

proc main_nim*(ctx: ref BuildContext): string {.inline.} =
  ## Absolute path to the main nim file to build
  ctx.projectPath / ctx.config.src

# Running from the wiish binary
var
  wiishPackagePath = ""

proc getWiishPackageRoot*():string =
  if wiishPackagePath == "":
    var path = shoutput("nimble", "path", "wiish").strip()
    if "Error:" in path:
      wiishPackagePath = currentSourcePath.parentDir.parentDir.parentDir
    else:
      wiishPackagePath = path
  return wiishPackagePath

proc DATADIR*():string =
  ## Return the path to the Wiish library data directory
  return getWiishPackageRoot()/"wiish"/"building"/"data"

proc getNimLibPath*(): string =
  ## Return the path to Nim's lib if it can be found
  let nimPath = findExe("nim")
  if nimPath == "":
    # Nim isn't installed or isn't in the PATH
    return ""
  let libDir = nimPath.splitPath().head.parentDir/"lib"
  if libDir.existsDir:
    return libDir
  return ""

proc resizePNG*(srcfile:string, outfile:string, width:int, height:int) =
  ## Resize a PNG image
  when defined(macosx):
    discard shoutput("sips",
      "-z", $height, $width,
      "--out", outfile,
      "-s", "format", "png",
      srcfile)
  else:
    warn "PNG resizing is not supported on this platform.  Using full-sized image (which may not work)"
    copyFile(srcfile, outfile)
    # raise newException(CatchableError, "PNG resizing is not supported on this platform")