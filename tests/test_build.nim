import algorithm
import os
import osproc
import random
import sequtils
import streams
import strformat
import strutils
import terminal
import unittest
import std/compilesettings

import wiish/building/buildutil
import wiishcli

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

template androidMaybe(body: untyped): untyped =
  if existsEnv("WIISH_BUILD_ANDROID"):
    body
  else:
    skipReason "set WIISH_BUILD_ANDROID=1 to run this test"

template runMaybe(body: untyped): untyped =
  ## Only run this code is WIISH_TEST_RUN is set
  if existsEnv("WIISH_TEST_RUN"):
    body
  else:
    skipReason "set WIISH_TEST_RUN=1 to run this test"

template vtest(name: string, body: untyped): untyped =
  ## Verbosely labeled test
  test(name):
    stderr.styledWriteLine(fgCyan, "  [START] ", name, resetStyle)
    body

template skipReason(reason: string): untyped =
  stderr.styledWriteLine(fgYellow, "    SKIP REASON: " & reason, resetStyle)
  skip

proc listAllChildPids(pid: int = 0): seq[string] =
  ## Return a list of all child pids of the current process
  ## There's probably all kinds of race conditions and problems with
  ## this method.  If someone has a better cross-platform way
  ## to kill all descendent processes, please add it here.
  when defined(macosx) or defined(linux):
    var pid = if pid == 0: getCurrentProcessId() else: pid
    let childpids = (shoutput("pgrep", "-P", $pid)).strip().splitLines()
    for child in childpids:
      if child == "":
        continue
      result.add $child
      result.add child.parseInt().listAllChildPids()

proc terminateAllChildren(pid: int = 0) =
  when defined(macosx) or defined(linux):
    while true:
      let children = listAllChildPids(pid)
      if children.len == 0:
        break
      for child in children:
        sh "kill", $child

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

const example_dirs = toSeq(walkDir(currentSourcePath.parentDir.parentDir/"examples")).filterIt(it.kind == pcDir).mapIt(it.path).sorted()

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

const run_sentinel = "WIISH RUN STARTING"

proc testWiishRun(dirname: string, args: seq[string], sleepTime = 5_000): bool =
  var p = startProcess(findExe"wiish", args = args)
  echo "    Running command:"
  echo "        cd ", dirname
  echo "        wiish ", args.join(" ")
  let err = p.errorStream()
  while true:
    let rc = p.peekExitCode()
    if rc == -1:
      # still running
      let line = err.readLine()
      if run_sentinel in line:
        break
    elif rc == 0:
      # quit
      assert false, "wiish run exited prematurely"
    else:
      assert false, "wiish run failed"
  echo &"    Waiting for {sleepTime}ms to see if it keeps running..."
  sleep(sleepTime)
  result = p.peekExitCode() == -1 # it should still be running
  terminateAllChildren(p.processID())
  discard p.waitForExit()
  defer: p.close()

suite "run":
  for example in example_dirs:
    # Desktop checks
    if fileExists example/"main_desktop.nim":
      vtest(example.extractFilename):
        runMaybe:
          check testWiishRun(example, @["run"], 5_000)
    
    # Mobile checks
    if fileExists example/"main_mobile.nim":
      for (name, args) in mobileBuildSetups:
        vtest(name & " " & example.extractFilename):
          runMaybe:
            var args = @["run"]
            case name
            of "android":
              args.add(@["--os", "android"])
            of "ios":
              args.add(@["--os", "ios-simulator"])
            of "mobiledev":
              args.add(@["--os", "mobiledev"])
            check testWiishRun(example, args, 15_000)

suite "examples":

  tearDown:
    let cmd = @["git", "clean", "-X", "-d", "-f", "--", "examples"]
    try:
      sh cmd
    except:
      echo "Error ^ while running: ", cmd.join(" ")

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
            runWiish "build", "--os", "ios-simulator", "--target", "ios-app"
        else:
          skipReason "only builds on macOS"
      
      vtest("android " & example.extractFilename):
        androidMaybe:
          withDir example:
            runWiish "build", "--os", "android"

suite "init":

  vtest "init and build":
    withDir tmpDir():
      echo absolutePath"."
      addConfigNims()
      runWiish "init", "desktop"
      withDir "desktop":
        runWiish "build"
    
  vtest "init and build --os ios":
    when defined(macosx):
      withDir tmpDir():
        echo absolutePath"."
        addConfigNims()
        runWiish "init", "iostest"
        withDir "iostest":
          runWiish "build", "--os", "ios-simulator", "--target", "ios-app"
    else:
      skipReason "only builds on macOS"
  
  vtest "init and build android":
    androidMaybe:
      withDir tmpDir():
        echo absolutePath"."
        addConfigNims()
        runWiish "init", "androidtest"
        withDir "androidtest":
          runWiish "build", "--os", "android"
