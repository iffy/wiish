import os
import strformat
import parsetoml
import ./build_macos
import ./build_windows
import ./config
import ./logging

const default_icon = slurp"./data/default.png"
const sample_toml = slurp"./data/sample.toml"
const sample_app = slurp"./data/sampleapp.nim"


proc doBuild*(directory:string = ".", macos:bool = false, windows:bool = false, linux:bool = false) =
  var
    macos = macos
    linux = linux
    windows = windows
  let config = getConfig(directory/"wiish.toml")
  if not macos and not windows and not linux:
    when defined(MacOSX):
      macos = true
    elif defined(Windows):
      windows = true
    elif defined(Linux):
      linux = true
  if macos:
    log("Building macOS desktop...")
    doMacBuild(directory, config)
  if windows:
    log("Building Windows desktop...")
    doWindowsBuild(directory, config)
  if linux:
    log("Building Linux desktop...")
    raise newException(CatchableError, &"Linux not supported yet")

proc doRun*(directory:string = ".") =
  let config = getConfig(directory/"wiish.toml")
  when defined(macosx):
    doMacRun(directory, config)
  elif defined(windows):
    doWindowsRun(directory, config)

proc doInit*(directory:string = ".") =
  directory.createDir()
  let conf_file = directory/"wiish.toml"
  if not conf_file.fileExists:
    writeFile(directory/"wiish.toml", sample_toml)
    echo &"wrote {conf_file}"
  let app_nim = directory/"myapp.nim"
  if not app_nim.fileExists:
    writeFile(app_nim, sample_app)
    echo &"wrote {app_nim}"
  echo &"""Initialized a new wiish app in {directory}

Run:    wiish run {directory}
Build:  wiish build {directory}
"""
