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
import argparse

const examples_dir = currentSourcePath.parentDir/"examples"
const EXAMPLE_NAMES = toSeq(examples_dir.walkDir()).filterIt(it.kind == pcDir).mapIt(it.path.extractFilename)

let p = newParser("wiish"):
  command "init":
    help("Create a new wiish application")
    arg("directory", default=".")
    option("-b", "--base-template", help="Template to use.", default="webview", choices = EXAMPLE_NAMES)
    run:
      doInit(directory = opts.directory, example = opts.base_template)
  command "build":
    help("Build a single-file app/binary")
    flag("--mac", help="Build macOS desktop app")
    flag("--win", help="Build Windows desktop app")
    flag("--linux", help="Build Linux desktop app")
    flag("--ios", help="Build iOS mobile app")
    flag("--android", help="Build Android mobile app")
    arg("directory", default=".")
    run:
      doBuild(
        directory = opts.directory,
        macos = opts.mac,
        ios = opts.ios,
        android = opts.android,
        windows = opts.win,
        linux = opts.linux)
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

if isMainModule:
  addHandler(newConsoleLogger())
  p.run()


