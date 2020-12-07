import os
import osproc
import strutils
import tables
import terminal
import ./config
when defined(macos):
  discard
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
    targetAndroidApk = "apk"
    targetLinuxBin = "bin"
  
  BuildContext* = object
    ## The context for all builds
    projectPath*: string
    targetOS*: TargetOS
    targetFormat*: TargetFormat
    verbose*: bool
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
    output_path*: string
      ## Build product path (.app, .dmg, .apk, etc...)
    nim_flags*: seq[string]
      ## Flags that should be set when compiling Nim code.
      ## Includes the flags from the config.

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


const
  NIMBASE_1_0_X* = slurp"data/nimbase-1.0.x.h"
  NIMBASE_1_2_X* = slurp"data/nimbase-1.2.x.h"
  NIMBASE_1_4_x* = slurp"data/nimbase-1.4.x.h"

proc viableTargets*(os: TargetOS): set[TargetFormat] =
  ## Return the TargetFormats that can be built for the given TargetOS
  case os
  of AutoDetectOS:
    result = {}
  of Android:
    result = {targetRun, targetAndroidApk}
  of Ios:
    result = {targetIosApp}
  of IosSimulator:
    result = {targetRun, targetIosApp}
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
  var fullmsg = ctx.logprefix & msg.join("")
  for c in fullmsg:
    stderr.write(c)
  stderr.write("\L")

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

proc DATADIR*():string {.deprecated: "Each plugin should have its own DATADIR".}=
  ## Return the path to the Wiish library data directory
  return getWiishPackageRoot()/"wiish"/"building"/"data"

proc getNimLibPath*(): string =
  ## Return the path to Nim's lib if it can be found
  let nimPath = findExe("nim")
  if nimPath == "":
    # Nim isn't installed or isn't in the PATH
    return ""
  let libDir = nimPath.splitPath().head.parentDir/"lib"
  if libDir.dirExists:
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
