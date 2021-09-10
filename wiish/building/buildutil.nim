import os
import osproc
import strutils
import tables
import terminal
import pixie

import ./config
when defined(macosx):
  import posix
else:
  import logging

const
  simulator_sdk_root* = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/"
  ios_sdk_root* = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/"

type
  TargetOS* = enum
    AutoDetectOS = "auto"
    
    Android = "android"
    Ios = "ios"
    IosSimulator = "ios-simulator"
    MobileDev = "mobiledev"

    Linux = "linux"
    Mac = "mac"
    Windows = "windows"
  
  TargetFormat* = enum
    targetAuto = "auto"
    targetRun = "run"
    targetMacApp = "app"
    targetMacDMG = "dmg"
    targetWinExe = "exe"
    targetWinInstaller = "win-installer"
    targetIosApp = "ios-app"
    targetIosIpa = "ios-ipa"
    targetAndroidApk = "apk"
    targetLinuxBin = "bin"
  
  BuildContext* = object
    ## The context for all builds
    projectPath*: string
      ## . when in the wiish project
    targetOS*: TargetOS
    targetFormat*: TargetFormat
    verbose*: bool
    config*: WiishConfig
    currentStep*: BuildStep
    currentPlugin*: string
    pluginData: TableRef[string, pointer]
    # data that is set during the build
    dist_dir*: string
      ## Directory where built output goes (final products)
    build_dir*: string
      ## Path where intermediate build files live
    executable_path*: string
      ## For builds that produce an executable, this is the path
      ## to that executable
    xcode_project_root*: string ## the dir containing the .xcodeproj file
    xcode_project_file*: string ## the .xcodeproj file
    xcode_build_scheme*: string ## the -scheme to build
    xcode_build_destination*: string ## the -destination to build

    ios_sdk_version*: string
    nim_flags*: seq[string]
      ## Flags that should be set when compiling Nim code.
      ## Includes the flags from the config.
    nim_run_flags*: seq[string]
      ## Flags that should be set when running Nim code for targetRun

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

proc viableTargets*(os: TargetOS): set[TargetFormat] =
  ## Return the TargetFormats that can be built for the given TargetOS
  case os
  of AutoDetectOS:
    result = {}
  of Android:
    result = {targetRun, targetAndroidApk}
  of Ios:
    result = {targetIosApp, targetIosIpa}
  of IosSimulator:
    result = {targetRun, targetIosApp, targetIosIpa}
  of MobileDev:
    result = {targetRun}
  of Mac:
    result = {targetRun, targetMacApp, targetMacDMG}
  of Windows:
    result = {targetRun, targetWinExe, targetWinInstaller}
  of Linux:
    result = {targetRun, targetLinuxBin}

#-------------------------------------------------------------
# ios
#-------------------------------------------------------------
proc simulator*(ctx: ref BuildContext): bool {.inline.} =
  ## Return whether this build is for the iOS simulator or not.
  ctx.targetOS == IosSimulator

proc ios_sdk_path*(ctx: ref BuildContext): string =
  ## Given an sdk version, return the path to the SDK
  if ctx.simulator:
    return simulator_sdk_root / "iPhoneSimulator" & ctx.ios_sdk_version & ".sdk"
  else:
    return ios_sdk_root / "iPhoneOS" & ctx.ios_sdk_version & ".sdk"

#-------------------------------------------------------------
# general
#-------------------------------------------------------------
proc parseTargetOS*(x: string): TargetOS {.inline.} =
  parseEnum[TargetOS](x, AutoDetectOS)

proc parseTargetFormat*(x: string): TargetFormat {.inline.} =
  parseEnum[TargetFormat](x, targetAuto)

template withDir*(dir: string, body: untyped): untyped =
  ## Execute a block of code within another directory.
  let origDir = getCurrentDir().absolutePath
  let dstDir = dir.absolutePath()
  try:
    setCurrentDir(dstDir)
    body
  finally:
    setCurrentDir(origDir)

proc sh*(args:varargs[string, `$`]) =
  ## Run a process, failing the program if it fails
  when defined(macosx):
    let origStdoutFlags = fcntl(stdout.getFileHandle(), F_GETFL)
  try:
    var p = startProcess(command = args[0],
      args = args[1..^1],
      options = {poUsePath, poParentStreams})
    if p.waitForExit() != 0:
      raise newException(CatchableError, "Error running process")
  finally:
    when defined(macosx):
      discard fcntl(stdout.getFileHandle(), F_SETFL, origStdoutFlags)
    else:
      discard

proc shoutput*(args:varargs[string, `$`]):string =
  ## Run a process and return the output as a string
  result = execProcess(command = args[0],
    args = args[1..^1],
    options = {poUsePath})

proc logprefix(ctx: ref BuildContext): string {.inline.} =
  "[wiish] " & $ctx[].currentStep & "/" & ctx[].currentPlugin & " "

proc log*(ctx: ref BuildContext, msg: varargs[string]) =
  var fullmsg = ctx.logprefix & msg.join("")
  for c in fullmsg:
    stderr.write(c)
  stderr.write("\L")
  stderr.flushFile()

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

proc resizePNG*(srcfile:string, outfile:string, width:int, height:int) =
  readImage(srcfile).resize(width, height).writeFile(outfile)
