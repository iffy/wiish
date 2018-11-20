import os
import osproc
import ospaths
import parsetoml
import sequtils
import strutils
import strformat
import tables
import logging
import ./build_macos
import ./build_ios
import ./build_windows
import ./build_linux
import ./build_android
import ./config
import ./buildutil

export doiOSRun
export doAndroidRun

type
  PackedFile = tuple[
    name: string,
    contents: string,
  ]

proc doBuild*(directory:string = ".", macos,ios,android,windows,linux:bool = false) =
  let
    configPath = directory/"wiish.toml"
  var
    macos = macos
    ios = ios
    android = android
    linux = linux
    windows = windows
  if not macos and not windows and not linux and not ios and not android:
    when defined(macosx):
      macos = true
    elif defined(windows):
      windows = true
    elif defined(linux):
      linux = true
  
  if macos:
    info "Building macOS desktop..."
    doMacBuild(directory, configPath)
  if ios:
    info "Building iOS app ..."
    discard doiOSBuild(directory, configPath)
  if android:
    info "Building Android app ..."
    discard doAndroidBuild(directory, configPath)
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
  when defined(macosx):
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

proc doInit*(directory:string, example:string) =
  let
    examples_dir = getWiishPackageRoot() / "examples"
    src = examples_dir / example
  if not src.dirExists:
    let possibles = toSeq(examples_dir.walkDir()).filterIt(it.kind == pcDir).mapIt(it.path.basename).join(", ")
    raise newException(CatchableError, &"""Unknown project template: {example}.  Acceptable values: {possibles}""")
  directory.createDir()
  
  echo &"Copying from {src} to {directory}"
  copyDir(src, directory)
  echo &"""Initialized a new wiish app in {directory}

Run:    wiish run {directory}
Build:  wiish build {directory}
"""
