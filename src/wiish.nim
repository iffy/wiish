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
    help("Package an application for distribution")
    flag("-h", "--help", help="Display help")
    flag("--mac", help="Build for macOS")
    arg("directory", default=".")
    run:
      if opts.help:
        echo p.help
        quit(0)
      doBuild(directory = opts.directory, macos = opts.mac)
  command "run":
    help("Run an application (from the current dir)")
    flag("-h", "--help", help="Display help")
    arg("directory", default=".")
    run:
      if opts.help:
        echo p.help
        quit(0)
      doRun(directory = opts.directory)

if isMainModule:
  echo "isMainModule"
  p.run()


