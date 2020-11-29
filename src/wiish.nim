## wiish command line interface
import argparse
import logging
# import macros
# import os
# import parseopt
# import parsetoml
import sequtils
# import strformat
# import strutils
# import sugar
# import tables
import wiish/building/buildutil
import wiish/building/build
import wiish/building/config
# import wiish/building/doctor

const
  examples_dir = currentSourcePath.parentDir/"examples"
  EXAMPLE_NAMES = toSeq(examples_dir.walkDir()).filterIt(it.kind == pcDir).mapIt(it.path.extractFilename)

let p = newParser("wiish"):
  command "init":
    help("Create a new wiish application")
    arg("directory", default=some("."))
    option("-b", "--base-template", help="Template to use.", default=some("webview"), choices = EXAMPLE_NAMES)
    run:
      doInit(directory = opts.directory, example = opts.base_template)
  command "build":
    nohelpflag()
    help("Build an application")
    # option("--os", choices = (low(TargetOS)..high(TargetOS)).mapIt($it))
    # option("--target", multiple = true, choices = (low(TargetFormat)..high(TargetFormat)).mapIt($it))
    # arg("directory", default=".")
    arg("extra", nargs = -1)
    # add config options
    # for opt in low(ConfigOption)..high(ConfigOption):
    #   case opt
    #   of IsSimulator:
    #     flag("--ios-simulator", help="Build for the iOS simulator instead of a real phone")
    #   else:
    #     discard
    #     # option("--" & $opt)
    run:
      # var parsed = parseConfig(opts.directory/"wiish.toml")
      # for opt in low(ConfigOption)..high(ConfigOption):
      #   case opt
      #   of IsSimulator:
      #     # cli_config.ios_simulator = opts.ios_simulator
      #     parsed.override($opt, true)
      #   else:
      #     discard
      # echo $opts
      # withDir(opts.directory):
        # putEnv("WIISH_TARGET_OS", $opts.os)
        # putEnv("WIISH_TARGET_FORMATS", opts.target.mapIt($it).join(","))
      var args = @[findExe"nim", "c", "-r", "wiish_build.nim"]
      args.add(opts.extra)
      sh(args)
      # handleBuild(opts.directory, opts.target, parsed)

  # command "run":
  #   help("Run an application (from the current dir)")
  #   flag("--verbose", "-v", help="Verbose log output")
  #   flag("--mobiledev", help="Run mobile app in simulated environment (e.g. web page)")
  #   flag("--ios", help="Run app in the iOS Simulator")
  #   flag("--android", help="Run app in the Android Emulator")
  #   arg("directory", default=".")
  #   run:
  #     # if opts.ios:
  #     #   doiOSRun(directory = opts.directory, verbose = opts.verbose)
  #     # elif opts.android:
  #     #   doAndroidRun(directory = opts.directory, verbose = opts.verbose)
  #     # elif opts.mobiledev:
  #     #   doMobileDevRun(directory = opts.directory, verbose = opts.verbose)
  #     # else:
  #     doDesktopRun(directory = opts.directory, parseConfig(opts.directory/"wiish.toml"))
  
  # command "doctor":
  #   help("Show what needs to be installed/configured to support various features")
  #   run:
  #     runWiishDoctor()
  
  # command "config":
  #   help("Display a full config file")
  #   run:
  #     echo defaultConfig()

if isMainModule:
  addHandler(newConsoleLogger())
  p.run()


