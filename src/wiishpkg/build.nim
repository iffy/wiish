import os
import osproc
import ospaths
import parsetoml
import sequtils
import strformat
import tables
import ./build_macos
import ./build_ios
import ./build_windows
import ./build_linux
import ./config
import ./logging
import ./wiishtypes

export doiOSRun

const default_icon = slurp"./data/default.png"

type
  PackedFile = tuple[
    name: string,
    contents: string,
  ]

const basepath = currentSourcePath.parentDir.joinPath("data/initapp")
const samples = toSeq(walkDirRec(basepath)).map(proc(x:string):PackedFile =
  return (x[basepath.len+1..^1], slurp(x))
)

# const sampledir = @[
#   ("wiish.toml", slurp("./data/initapp/wiish.toml")),
#   ("wiish.toml", slurp("./data/initapp/wiish.toml")),
#   ("wiish.toml", slurp("./data/initapp/wiish.toml")),
# ]
# sample_toml = slurp"./data/sample.toml"
# const sample_desktop = slurp"./data/sampledesktop.nim"
# const sample_mobile = slurp"./data/samplemobile.nim"


proc doBuild*(directory:string = ".", macos:bool = false, ios:bool = false, windows:bool = false, linux:bool = false) =
  var
    macos = macos
    ios = ios
    linux = linux
    windows = windows
  let config = getDesktopConfig(directory/"wiish.toml")
  if not macos and not windows and not linux:
    when defined(macDesktop):
      macos = true
    elif defined(windows):
      windows = true
    elif defined(linux):
      linux = true
  if macos:
    log("Building macOS desktop...")
    doMacBuild(directory, config)
  if ios:
    log("Building iOS mobile...")
    discard doiOSBuild(directory, config)
  if windows:
    log("Building Windows desktop...")
    doWindowsBuild(directory, config)
  if linux:
    log("Building Linux desktop...")
    doLinuxBuild(directory, config)

proc doDesktopRun*(directory:string = ".") =
  ## Run the application
  var
    nim_bin: string
    args: seq[string]
  let config = getDesktopConfig(directory/"wiish.toml")
  let src_file = directory/config.src
  when defined(macDesktop):
    nim_bin = "nim"
    args.add("objc")
  elif defined(windows):
    nim_bin = "nim.exe"
    args.add("c")
  elif defined(linux):
    nim_bin = "nim"
    args.add("c")
  for flag in config.nimflags:
    args.add(flag)
  args.add("-d:glfwStaticLib")
  args.add("-r")
  args.add(src_file)
  var p = startProcess(command=nim_bin, args = args, options = {poUsePath, poParentStreams})
  let result = p.waitForExit()
  quit(result)

proc doInit*(directory:string = ".") =
  directory.createDir()
  for sample in samples:
    writeFile(directory/sample.name, sample.contents)
    echo &"wrote {sample.name}"
  echo &"""Initialized a new wiish app in {directory}

Run:    wiish run {directory}
Build:  wiish build {directory}
"""
