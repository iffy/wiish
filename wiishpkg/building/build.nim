import os
import osproc
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
  BuildTarget* = enum
    MacApp = "mac",
    MacDmg = "mac-dmg",
    Ios = "ios",
    Android = "android",
    WinExe = "win",
    WinInstaller = "win-installer",
    LinuxBin = "linux",

proc doBuild*(directory:string = ".", target:seq[BuildTarget] = @[]) =
  let
    configPath = directory/"wiish.toml"
  var target:seq[BuildTarget] = target
  if target.len == 0:
    when defined(macosx):
      target.add(MacApp)
    elif defined(windows):
      target.add(WinExe)
    elif defined(linux):
      target.add(LinuxBin)
  
  if MacApp in target:
    info "Building macOS desktop..."
    doMacBuild(directory, configPath)

  if Ios in target:
    info "Building iOS app ..."
    let outputfile = doiOSBuild(directory, configPath)
    info "Built: " & outputfile

  if Android in target:
    info "Building Android app ..."
    let outputfile = doAndroidBuild(directory, configPath)
    info "Built: " & outputfile

  if WinExe in target:
    info "Building Windows desktop..."
    doWindowsBuild(directory, configPath)

  if LinuxBin in target:
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
  args.add("-d:ssl")
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
    let possibles = toSeq(examples_dir.walkDir()).filterIt(it.kind == pcDir).mapIt(it.path.extractFilename).join(", ")
    raise newException(CatchableError, &"""Unknown project template: {example}.  Acceptable values: {possibles}""")
  directory.createDir()
  
  echo &"Copying from {src} to {directory}"
  copyDir(src, directory)
  echo &"""Initialized a new wiish app in {directory}

Run:    wiish run {directory}
Build:  wiish build {directory}
"""
