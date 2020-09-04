import os
import osproc
import strutils
import logging

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
  NIMBASE_H* = slurp"data/nimbase.h"

template withDir*(dir: string, body: untyped): untyped =
  let origDir = getCurrentDir()
  setCurrentDir(dir)
  body
  setCurrentDir(origDir)

proc run*(args:varargs[string, `$`]) =
  ## Run a process, failing the program if it fails
  var p = startProcess(command = args[0],
    args = args[1..^1],
    options = {poUsePath, poParentStreams})
  if p.waitForExit() != 0:
    raise newException(CatchableError, "Error running process")

proc runoutput*(args:varargs[string, `$`]):string =
  ## Run a process and return the output as a string
  result = execProcess(command = args[0],
    args = args[1..^1],
    options = {poUsePath})

# Running from the wiish binary
var
  wiishPackagePath = ""

proc getWiishPackageRoot*():string =
  if wiishPackagePath == "":
    var path = runoutput("nimble", "path", "wiish").strip()
    if "Error:" in path:
      wiishPackagePath = currentSourcePath.parentDir.parentDir.parentDir
    else:
      wiishPackagePath = path
  return wiishPackagePath

proc DATADIR*():string =
  ## Return the path to the Wiish library data directory
  return getWiishPackageRoot()/"src"/"wiish"/"building"/"data"

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
    discard runoutput("sips",
      "-z", $height, $width,
      "--out", outfile,
      "-s", "format", "png",
      srcfile)
  else:
    warn "PNG resizing is not supported on this platform.  Using full-sized image (which may not work)"
    copyFile(srcfile, outfile)
    # raise newException(CatchableError, "PNG resizing is not supported on this platform")