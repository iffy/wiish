import unittest
import terminal
import os
import osproc
import strformat
import strutils
import sequtils
import random
import wiish/building/buildutil
import wiishcli
import std/compilesettings

randomize()

const TMPROOT = currentSourcePath.parentDir/"_testtmp"
if dirExists(TMPROOT):
  echo "removing old test dir ", TMPROOT
  removeDir(TMPROOT)

proc tmpDir(): string {.used.} =
  result = TMPROOT / &"wiishtest{random.rand(10000000)}"
  createDir(result)

proc addConfigNims() =
  var guts: string
  for path in querySettingSeq(searchPaths):
    let escaped = path.replace("\\", "\\\\")
    guts.add(&"switch(\"path\", \"{escaped}\")\n")
  writeFile("config.nims", guts)
  echo "added config.nims:\n", guts

template vtest(name: string, body: untyped): untyped =
  ## Verbosely labeled test
  test(name):
    stderr.styledWriteLine(fgCyan, "  [START] ", name, resetStyle)
    body

template skipReason(reason: string): untyped =
  stderr.styledWriteLine(fgYellow, "  SKIP REASON: " & reason, resetStyle)
  skip

when defined(macosx):
  const desktopBuildSetups = [
    ("macos", @["--os:macosx"]),
    ("windows", @["--os:windows"]),
  ]
  const mobileBuildSetups = [
    ("ios", @["--os:macosx", "-d:ios", "--threads:on", "--gc:orc"]),
    ("android", @["--os:linux", "-d:android", "--noMain", "--threads:on", "--gc:orc"]),
    ("mobiledev", @["-d:wiish_mobiledev", "--gc:orc"])
  ]
elif defined(windows):
  const desktopBuildSetups = [
    ("windows", @["--os:windows"]),
  ]
  const mobileBuildSetups = [
    ("android", @["--os:linux", "-d:android", "--noMain", "--threads:on", "--gc:orc"]),
    ("mobiledev", @["-d:wiish_mobiledev", "--gc:orc"])
  ]
else:
  const desktopBuildSetups = [
    ("linux", @["--os:linux"]),
  ]
  const mobileBuildSetups = [
    ("android", @["--os:linux", "-d:android", "--noMain", "--threads:on", "--gc:orc"]),
    ("mobiledev", @["-d:wiish_mobiledev", "--gc:orc"])
  ]

const example_dirs = toSeq(walkDir(currentSourcePath.parentDir.parentDir/"examples")).filterIt(it.kind == pcDir).mapIt(it.path)

suite "checks":
  for example in example_dirs:
    # Desktop checks
    if fileExists example/"main_desktop.nim":
      for (name, args) in desktopBuildSetups:
        vtest(name & " " & example.extractFilename):
          var cmd = @["nim", "check", "--hints:off", "-d:testconcepts"]
          cmd.add(args)
          cmd.add(example / "main_desktop.nim")
          let cmdstr = cmd.join(" ")
          checkpoint "COMMAND: " & cmdstr
          check execCmd(cmdstr) == 0
    
    # Mobile checks
    if fileExists example/"main_mobile.nim":
      for (name, args) in mobileBuildSetups:
        vtest(name & " " & example.extractFilename):
          var cmd = @["nim", "check", "--hints:off", "-d:testconcepts"]
          cmd.add(args)
          cmd.add(example / "main_mobile.nim")
          let cmdstr = cmd.join(" ")
          checkpoint "COMMAND: " & cmdstr
          check execCmd(cmdstr) == 0

suite "examples":

  teardown:
    let cmd = @["git", "clean", "-X", "-d", "-f", "--", "examples/"]
    try:
      sh cmd
    except:
      echo "Error ^ while running: ", $cmd

  # Build and check all the examples/
  for example in example_dirs:
    
    # Desktop example apps
    if fileExists example/"main_desktop.nim":
      vtest("desktop " & example.extractFilename):
        withDir example:
          runWiish "build"
    
    # Mobile example apps
    if fileExists example/"main_mobile.nim":
      vtest("ios " & example.extractFilename):
        when defined(macosx):
          withDir example:
            runWiish "build", "--os", "ios"
        else:
          skipReason "only builds on macOS"
      
      vtest("android " & example.extractFilename):
        if existsEnv("WIISH_BUILD_ANDROID"):
          withDir example:
            runWiish "build", "--os", "android"
        else:
          skipReason "only builds if WIISH_BUILD_ANDROID is set"

suite "init":

  vtest "init and build":
    withDir tmpDir():
      addConfigNims()
      runWiish "init", "desktop"
      withDir "desktop":
        runWiish "build"
    
  vtest "init and build --os ios":
    when defined(macosx):
      withDir tmpDir():
        addConfigNims()
        runWiish "init", "iostest"
        withDir "iostest":
          runWiish "build", "--os", "ios"
    else:
      skipReason "only builds on macOS"
  
  vtest "init and build android":
    if not existsEnv("WIISH_BUILD_ANDROID"):
      skipReason "only builds if WIISH_BUILD_ANDROID is set"
    else:
      withDir tmpDir():
        addConfigNims()
        runWiish "init", "androidtest"
        withDir "androidtest":
          runWiish "build", "--os", "android"
