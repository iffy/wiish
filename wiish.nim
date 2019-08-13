## wiish command line interface
import strformat
import parseopt
import tables
import macros
import os
import ospaths
import logging
import sequtils
import parsetoml
import wiishpkg/building/build
import wiishpkg/building/doctor
import argparse
import sugar

const examples_dir = currentSourcePath.parentDir/"examples"
const EXAMPLE_NAMES = toSeq(examples_dir.walkDir()).filterIt(it.kind == pcDir).mapIt(it.path.extractFilename)

proc handleBuild(directory:string, target:seq[string]) =
  doBuild(
    directory = directory,
    target = target.map(proc (it: string): BuildTarget =
      return parseEnum[BuildTarget](it)
    ),
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
    option("-t", "--target", multiple = true, choices = @[
      $BuildTarget.MacApp,
      $BuildTarget.MacDmg,
      $BuildTarget.Ios,
      $BuildTarget.Android,
      $BuildTarget.WinExe,
      $BuildTarget.WinInstaller,
      $BuildTarget.LinuxBin,
    ])
    arg("directory", default=".")
    run:
      handleBuild(opts.directory, opts.target)

  command "run":
    help("Run an application (from the current dir)")
    flag("--verbose", "-v", help="Verbose log output")
    flag("--ios", help="Run app in the iOS Simulator")
    flag("--android", help="Run app in the Android Emulator")
    arg("directory", default=".")
    run:
      if opts.ios:
        doiOSRun(directory = opts.directory)
      elif opts.android:
        doAndroidRun(directory = opts.directory, verbose = opts.verbose)
      else:
        doDesktopRun(directory = opts.directory)
  
  command "doctor":
    help("Show what needs to be installed/configured to support various features")
    run:
      runWiishDoctor()

if isMainModule:
  addHandler(newConsoleLogger())
  p.run()


