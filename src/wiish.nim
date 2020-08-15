## wiish command line interface
import strformat
import strutils
import parseopt
import tables
import macros
import os
import ospaths
import logging
import sequtils
import parsetoml
import wiish/building/config
import wiish/building/build
import wiish/building/doctor
import argparse
import sugar

const examples_dir = currentSourcePath.parentDir/"examples"
const EXAMPLE_NAMES = toSeq(examples_dir.walkDir()).filterIt(it.kind == pcDir).mapIt(it.path.extractFilename)

proc handleBuild(directory:string, target:string, parsed_config:TomlValueRef) =
  doBuild(
    directory = directory,
    target = parseEnum[BuildTarget](target),
    parsed_config = parsed_config,
  )


let p = newParser("wiish"):
  command "init":
    help("Create a new wiish application")
    arg("directory", default=".")
    option("-b", "--base-template", help="Template to use.", default="webview", choices = EXAMPLE_NAMES)
    run:
      doInit(directory = opts.directory, example = opts.base_template)
  
  command "build":
    help("Build an application")
    option("-t", "--target", choices = @[
      $BuildTarget.MacApp,
      # $BuildTarget.MacDmg,
      $BuildTarget.Ios,
      $BuildTarget.Android,
      $BuildTarget.WinExe,
      # $BuildTarget.WinInstaller,
      $BuildTarget.LinuxBin,
    ])
    arg("directory", default=".")
    # --- ios options
    for opt in low(ConfigOption)..high(ConfigOption):
      case opt
      of IsSimulator:
        flag("--ios-simulator", help="Build for the iOS simulator instead of a real phone")
      else:
        discard
    run:
      var parsed = parseConfig(opts.directory/"wiish.toml")
      for opt in low(ConfigOption)..high(ConfigOption):
        case opt
        of IsSimulator:
          # cli_config.ios_simulator = opts.ios_simulator
          parsed.override($opt, true)
        else:
          discard
      handleBuild(opts.directory, opts.target, parsed)

  command "run":
    help("Run an application (from the current dir)")
    flag("--verbose", "-v", help="Verbose log output")
    flag("--ios", help="Run app in the iOS Simulator")
    flag("--android", help="Run app in the Android Emulator")
    arg("directory", default=".")
    run:
      if opts.ios:
        doiOSRun(directory = opts.directory, verbose = opts.verbose)
      elif opts.android:
        doAndroidRun(directory = opts.directory, verbose = opts.verbose)
      else:
        doDesktopRun(directory = opts.directory, parseConfig(opts.directory/"wiish.toml"))
  
  command "doctor":
    help("Show what needs to be installed/configured to support various features")
    run:
      runWiishDoctor()
  
  command "config":
    help("Display a full config file")
    run:
      echo defaultConfig()

if isMainModule:
  addHandler(newConsoleLogger())
  p.run()


