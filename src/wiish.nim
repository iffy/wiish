## wiish command line interface
import strformat
import parseopt
import tables
import macros
import os
import parsetoml
import wiishpkg/build
import argparse

let p = newParser("wiish"):
  flag("-h", "--help", help="Display help")
  run:
    if opts.help:
      echo p.help
      quit(0)
  command "init":
    help("Create a new wiish application")
    flag("-h", "--help", help="Display help")
    arg("directory", default=".")
    run:
      if opts.help:
        echo p.help
        quit(0)
      doInit(directory = opts.directory)
  command "build":
    help("Build a single-file app/binary")
    flag("-h", "--help", help="Display help")
    flag("--mac", help="Build macOS desktop app")
    flag("--win", help="Build Windows desktop app")
    flag("--linux", help="Build Linux desktop app")
    flag("--ios", help="Build iOS mobile app")
    arg("directory", default=".")
    run:
      if opts.help:
        echo p.help
        quit(0)
      doBuild(
        directory = opts.directory,
        macos = opts.mac,
        ios = opts.ios,
        windows = opts.win,
        linux = opts.linux)
  command "run":
    help("Run an application (from the current dir)")
    flag("-h", "--help", help="Display help")
    flag("--ios", help="Run app in the iOS Simulator")
    arg("directory", default=".")
    run:
      if opts.help:
        echo p.help
        quit(0)
      if opts.ios:
        doiOSRun(directory = opts.directory)
      else:
        doDesktopRun(directory = opts.directory)

if isMainModule:
  p.run()


