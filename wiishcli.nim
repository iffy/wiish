## wiish command line interface
import argparse
import logging
import sequtils
import strformat
import wiish/doctor
import wiish/building/buildutil

const
  EXAMPLE_NAMES = toSeq((currentSourcePath.parentDir.parentDir/"examples").walkDir()).filterIt(it.kind == pcDir).mapIt(it.path.extractFilename)
  WIISHBUILDFILE = "wiish_build.nim"

proc baseNimArgs(): seq[string] {.inline.} =
  ## Return the basic compile args for compiling WIISHBUILDFILE
  ## in the current directory
  @[
    findExe"nim", "c",
    "--hints:off",
    "--verbosity:0",
    "-r", WIISHBUILDFILE,
  ]

proc onlyInWiishProject() =
  ## Quit the process with a warning if this is not being run within
  ## a wiish project.
  if not WIISHBUILDFILE.fileExists:
    stderr.writeLine &"ERROR: {WIISHBUILDFILE} not found. This command can only be run within a wiish project. Create one with: wiish init"
    quit(1)

proc doInit(directory: string, example: string) =
  ## Create a new Wiish project in the given directory
  let
    examples_dir = getWiishPackageRoot() / "examples"
    src = examples_dir / example
  if not src.dirExists:
    raise newException(ValueError, &"Unknown project template: {example}.  Acceptable values: {EXAMPLE_NAMES}")
  directory.createDir()
  
  echo &"Copying template from {src} to {directory}"
  copyDir(src, directory)
  echo &"""Initialized a new wiish app in {directory}

cd {directory}
wiish run
wiish build
"""

import wiish/plugins/standard
import wiish/plugins/webview
import wiish/plugins/sdl2

proc runDoctor(): bool =
  ## Run doctor for all the things that come with Wiish
  ## Return true if everything is set, else false
  var results: seq[DoctorResult]
  results.add standard.checkDoctor()
  results.add webview.checkDoctor()
  results.add sdl2.checkDoctor()
  for r in results:
    r.display()
  result = results.ok()

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
    arg("extra", nargs = -1)
    run:
      onlyInWiishProject()
      var args = baseNimArgs()
      args.add "build"
      args.add opts.extra
      sh args

  command "run":
    nohelpflag()
    help("Run the application")
    arg("extra", nargs = -1)
    run:
      onlyInWiishProject()
      var args = baseNimArgs()
      args.add "run"
      args.add opts.extra
      sh args

  command "doctor":
    help("Show what needs to be installed/configured to support various features")
    run:
      echo "oo ee oo ah ah"
      if not runDoctor():
        quit(1)
  
  # command "config":
  #   help("Display a full config file")
  #   run:
  #     echo defaultConfig()

proc runWiish*(args: varargs[string]) =
  ## Run a wiish command-line command
  p.run(toSeq(args))

if isMainModule:
  addHandler(newConsoleLogger())
  p.run()
