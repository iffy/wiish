## wiish command line interface
import argparse
import logging
import sequtils
import strformat
import strutils

import wiish/building/buildutil
import wiish/doctor

import wiish/plugins/standard/standard_doctor
import wiish/plugins/webview/webview_doctor

proc extractVersion(nimblefile: string): string =
  for line in nimblefile.splitLines():
    if line.startsWith("version"):
      result = line.split("\"")[1]

const
  VERSION = extractVersion(slurp"./wiish.nimble")
  VERBOSE = defined(verbose)

const
  EXAMPLE_NAMES = toSeq((currentSourcePath.parentDir.parentDir/"examples").walkDir()).filterIt(it.kind == pcDir).mapIt(it.path.extractFilename)
  WIISHBUILDFILE = "wiish_build.nim"

proc baseNimArgs(): seq[string] {.inline.} =
  ## Return the basic compile args for compiling WIISHBUILDFILE
  ## in the current directory
  result.add findExe"nim"
  result.add "c"
  if not VERBOSE:
    result.add "--hints:off"
    result.add "--verbosity:0"
  result.add "-r"
  result.add WIISHBUILDFILE

proc onlyInWiishProject() =
  ## Quit the process with a warning if this is not being run within
  ## a wiish project.
  if not WIISHBUILDFILE.fileExists:
    let pwd = getCurrentDir().absolutePath()
    stderr.writeLine &"ERROR: {WIISHBUILDFILE} not found in {pwd}. This command can only be run within a wiish project. Create one with: wiish init"
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

proc toSet[T](x: seq[T]): set[T] =
  for item in x:
    result.incl(item)

proc runDoctor(plugins: seq[string] = @[], targetOS: set[TargetOS] = {}, targetFormat: set[TargetFormat] = {}): bool =
  ## Run doctor for all the things that come with Wiish
  ## Return true if everything is set, else false
  var results: seq[DoctorResult]
  results.add standard_doctor.checkDoctor()
  results.add webview_doctor.checkDoctor()
  var valid: seq[DoctorResult]
  for r in results:
    let selected = r.isSelected(targetOS, targetFormat, plugins)
    r.display(selected)
    if selected:
      valid.add(r)
  result = valid.ok()

let p = newParser("wiish "):
  help("Wiish v" & VERSION)
  flag("-v", "--version", help = "Show version and quit", shortcircuit = true)

  command "step", "Low level":
    nohelpflag()
    help("Run a single build step")
    arg("extra", nargs = -1)
    run:
      onlyInWiishProject()
      var args = baseNimArgs()
      args.add "step"
      args.add opts.extra
      sh args

  command "init", "High level":
    help("Create a new wiish application")
    arg("directory", default=some("."))
    option("-b", "--base-template", help="Template to use.", default=some("webview"), choices = EXAMPLE_NAMES)
    run:
      doInit(directory = opts.directory, example = opts.base_template)
  
  command "build", "High level":
    nohelpflag()
    help("Build an application")
    arg("extra", nargs = -1)
    run:
      onlyInWiishProject()
      var args = baseNimArgs()
      args.add "build"
      args.add opts.extra
      sh args

  command "run", "High level":
    nohelpflag()
    help("Run the application")
    arg("extra", nargs = -1)
    run:
      onlyInWiishProject()
      var args = baseNimArgs()
      args.add "run"
      args.add opts.extra
      sh args

  command "doctor", "High level":
    help("""
Show what needs to be installed/configured.
You can filter which checks are performed.  For instance, if you only want to
know what you need to support building for Android, run with

  wiish doctor --os android

Or if you only want to know what you need to do to support building with
the 'webview' plugin do:

  wiish doctor --plugin webview --plugin standard

""".strip())
    option("--os", multiple = true, choices = (low(TargetOS)..high(TargetOS)).mapIt($it),
      help = "If given, only show information relevant to this OS.")
    option("-t", "--target", multiple = true, choices = (low(TargetFormat)..high(TargetFormat)).mapIt($it),
      help = "If given, only show information relevant to building the given target.")
    option("-p", "--plugin", multiple = true,
      help = "If given, only show information relevant to the given plugins.")
    run:
      echo "oo ee oo ah ah"
      if not runDoctor(opts.plugin,
          opts.os.mapIt(parseTargetOS(it)).toSet(),
          opts.target.mapIt(parseTargetFormat(it)).toSet()):
        echo "failed"
        quit(1)
      else:
        echo "ting tang walla walla bing bang!"
        echo "ok"
  
  # command "config":
  #   help("Display a full config file")
  #   run:
  #     echo defaultConfig()

proc runWiish*(args: varargs[string]) =
  ## Run a wiish command-line command
  try:
    p.run(toSeq(args))
  except ShortCircuit as e:
    if e.flag == "version":
      echo "wiish ", VERSION

if isMainModule:
  addHandler(newConsoleLogger())
  try:
    p.run()
  except ShortCircuit as e:
    if e.flag == "version":
      echo "wiish ", VERSION
