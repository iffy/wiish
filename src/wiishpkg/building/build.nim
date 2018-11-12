import os
import osproc
import ospaths
import parsetoml
import sequtils
import strformat
import tables
import logging
import ./build_macos
import ./build_ios
import ./build_windows
import ./build_linux
import ./config
import ./buildutil
import ../defs

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


proc doBuild*(directory:string = ".", macos:bool = false, ios:bool = false, windows:bool = false, linux:bool = false) =
  let
    configPath = directory/"wiish.toml"
  var
    macos = macos
    ios = ios
    linux = linux
    windows = windows
  if not macos and not windows and not linux and not ios:
    when macDesktop:
      macos = true
    elif defined(windows):
      windows = true
    elif defined(linux):
      linux = true
  
  if macos:
    info "Building macOS desktop..."
    doMacBuild(directory, configPath)
  if ios:
    info "Building iOS mobile..."
    discard doiOSBuild(directory, configPath)
  if windows:
    info "Building Windows desktop..."
    doWindowsBuild(directory, configPath)
  if linux:
    info "Building Linux desktop..."
    doLinuxBuild(directory, configPath)

proc doDesktopRun*(directory:string = ".") =
  ## Run the desktop application
  var
    args: seq[string]
    src_file: string
    config: Config
  let
    configPath = directory/"wiish.toml"
  when macDesktop:
    args.add("nim")
    config = getMacosConfig(configPath)
  elif defined(windows):
    args.add("nim.exe")
    config = getWindowsConfig(configPath)
  elif defined(linux):
    args.add("nim")
    config = getLinuxConfig(configPath)
  else:
    raise newException(CatchableError, "Unknown OS")
  src_file = directory/config.src
  args.add("c")
  args.add(config.nimflags)
  # args.add("-d:glfwStaticLib")
  # if defined(linux):
  #   args.add("--dynlibOverride:SDL2")
  args.add("-d:wiishDev")
  args.add("--threads:on")
  args.add("-r")
  args.add(src_file)
  echo "args: ", args
  run(args)
  quit(0)

proc doInit*(directory:string = ".") =
  directory.createDir()
  for sample in samples:
    writeFile(directory/sample.name, sample.contents)
    echo &"wrote {sample.name}"
  echo &"""Initialized a new wiish app in {directory}

Run:    wiish run {directory}
Build:  wiish build {directory}
"""
