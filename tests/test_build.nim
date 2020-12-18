import algorithm
import logging
import os
import osproc
import random
import sequtils
import std/compilesettings
import std/exitprocs
import streams
import strformat
import strutils
import tables
import terminal
import unittest

import ./formatter

import wiish/building/buildutil
import wiishcli

useCustomUnittestFormatter()

randomize()

const example_dirs = toSeq(walkDir(currentSourcePath.parentDir.parentDir/"examples")).filterIt(it.kind == pcDir).mapIt(it.path).sorted()
const examples = example_dirs.mapIt(it.extractFilename())


const TMPROOT = currentSourcePath.parentDir/"_testtmp"
if dirExists(TMPROOT):
  info "removing old test dir ", TMPROOT
  removeDir(TMPROOT)

proc tmpDir(): string {.used.} =
  result = TMPROOT / &"wiishtest{random.rand(10000000)}"
  createDir(result)

proc addConfigNims() =
  ## Add a config.nims file to the current directory
  var guts: string
  for path in querySettingSeq(searchPaths):
    let escaped = path.replace("\\", "\\\\")
    guts.add(&"switch(\"path\", \"{escaped}\")\n")
  writeFile("config.nims", guts)
  stdout.writeLine("added config.nims:\n" & guts)

template androidBuildMaybe(body: untyped): untyped =
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

template skipReason(reason: string): untyped =
  # stdout.styledWriteLine(fgYellow, reason, resetStyle)
  doSkip(reason)

const desktop_mains = ["main_desktop.nim", "main.nim"]
const mobile_mains = ["main_mobile.nim", "main.nim"]
proc desktopMain(root: string): string =
  ## Return the main.nim for a desktop app in the given dir
  for name in desktop_mains:
    if fileExists(root / name):
      return root / name

proc mobileMain(root: string): string =
  ## Return the main.nim for a mobile app in the given dir
  for name in mobile_mains:
    if fileExists(root / name):
      return root / name

proc listAllChildPids(pid: int = 0): seq[int] =
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
      result.add child.parseInt()
      result.add child.parseInt().listAllChildPids()

proc isAlive(pid: int): bool =
  when defined(macosx) or defined(linux):
    try:
      discard shoutput("kill", "-0", $pid)
      result = true
    except:
      result = false

proc terminateAllChildren(pid: int = 0) =
  ## Recursively terminate all child processes.
  debug "Terminating children of: ", $pid
  when defined(macosx) or defined(linux):
    var round1 = pid.listAllChildPids()
    var round2: seq[int]
    while round1.len > 0:
      var child = round1[0]
      round1.delete(0, 0)
      var children = listAllChildPids(child)
      for child in children:
        if child notin round1 and child notin round2:
          round1.add(child)
      try:
        debug "kill ", $child
        discard shoutput("kill", $child)
      except:
        break
      if child.isAlive():
        round2.add(child)

    while round2.len > 0:
      sleep(100)
      var child = round2[0]
      round2.delete(0, 0)
      if not child.isAlive():
        continue
      var children = listAllChildPids(child)
      for child in children:
        if child notin round2:
          round2.add(child)
      try:
        debug "kill -9 ", $child
        discard shoutput("kill", "-9", $child)
      except:
        discard
  debug "Done terminating children of: ", $pid
      

#---------------------------------------------------------------
# Support Tables
#---------------------------------------------------------------
type
  SupportStatus = enum
    NotWorking
    NotApplicable
    Planned
    Working

var supportedBranches = initTable[string, SupportStatus]()

proc key(targetOS: TargetOS, example: string, action: string): string =
  result.add $targetOS
  result.add "/"
  result.add example
  result.add "/"
  result.add action

proc markSupport(targetOS: TargetOS, example: string, action: string, status = NotWorking) =
  let key = key(targetOS, example, action)
  supportedBranches[key] = status

proc supportStatus(targetOS: TargetOS, example: string, action: string): SupportStatus =
  supportedBranches.getOrDefault(key(targetOS, example, action), NotWorking)

template forMatrix(targetOS: TargetOS, example: string, action: string, body: untyped): untyped =
  block:
    let expectedStatus = supportStatus(targetOS, example, action)
    try:
      if expectedStatus == NotApplicable:
        discard
      else:
        body
        markSupport(targetOS, example, action, Working)
    except:
      case expectedStatus
      of NotWorking:
        setProgramResult 1
        raise
      of NotApplicable:
        echo "Failed, but expected NotApplicable"
      of Planned:
        echo "Failed, but not expected to pass yet"
      of Working:
        markSupport(targetOS, example, action, NotWorking)
      

const actions = ["run", "build"]

proc str(status: SupportStatus): string =
  case status
  of NotWorking:
    "No"
  of NotApplicable:
    "-"
  of Working:
    "Yes"
  of Planned:
    "Planned"

proc displaySupport(hostOS: TargetOS) =
  var rows:seq[seq[string]]
  var col1max = 0
  var col2max = 0
  var col3max = 0
  var col4max = 0
  for targetOS in low(TargetOS)..high(TargetOS):
    if targetOS == AutoDetectOS:
      continue
    for example in examples:
      let run_key = key(targetOS, example, "run")
      let build_key = key(targetOS, example, "build")
      let run_status = supportedBranches.getOrDefault(run_key)
      let build_status = supportedBranches.getOrDefault(build_key)
      if run_status == NotApplicable and build_status == NotApplicable:
        continue
      if run_status == NotWorking or build_status == NotWorking:
        setProgramResult 1
      rows.add @[$targetOS, example, run_status.str(), build_status.str()]
      col1max = max(col1max, rows[^1][0].len)
      col2max = max(col2max, rows[^1][1].len)
      col3max = max(col3max, rows[^1][2].len)
      col4max = max(col4max, rows[^1][3].len)
  proc pad(x: string, size: int): string =
    result.add x
    if x.len < size:
      result.add " ".repeat(size - x.len)
  stdout.writeLine "| Host OS | `--os` | Example | `wiish run` | `wiish build` |"
  stdout.writeLine "|---------|-----------|---------|:---:|:-----:|"
  proc color(status: string): ForegroundColor =
    if status == "No":
      result = fgRed
    elif status == "Yes":
      result = fgGreen
    elif status == "Planned":
      result = fgYellow
    else:
      result = fgWhite
  for row in rows:
    stdout.styledWrite "| " & $hostOS
    stdout.styledWrite " | " & row[0].pad(col1max)
    stdout.styledWrite " | " & row[1].pad(col2max)
    stdout.styledWrite " | ", color(row[2]), row[2].pad(col3max)
    stdout.styledWrite " | ", color(row[3]), row[3].pad(col4max)
    stdout.styledWrite " |\l"


# The MobileDev target is never built
for example in examples:
  markSupport(MobileDev, example, "build", NotApplicable)

#---------------------------------------------------------------
# Build matrix
#---------------------------------------------------------------
when defined(macosx):
  const THISOS = Mac
  const buildTargets = {Mac, Windows, IosSimulator, Android, MobileDev}
  for example in examples:
    for action in actions:
      markSupport(Windows, example, action, NotApplicable)
      markSupport(Linux, example, action, NotApplicable)
      markSupport(Ios, example, action, Planned)

elif defined(windows):
  const THISOS = Windows
  const buildTargets = {Windows, MobileDev}
  for example in examples:
    for action in actions:
      markSupport(Mac, example, action, NotApplicable)
      markSupport(Ios, example, action, NotApplicable)
      markSupport(IosSimulator, example, action, NotApplicable)
      markSupport(Linux, example, action, NotApplicable)
    markSupport(Windows, example, "build", Planned) # Building for Windows doesn't work yet

else:
  const THISOS = Linux
  const buildTargets = {Linux, Android, MobileDev}
  for example in examples:
    for action in actions:
      markSupport(Mac, example, action, NotApplicable)
      markSupport(Ios, example, action, NotApplicable)
      markSupport(IosSimulator, example, action, NotApplicable)
      markSupport(Windows, example, action, NotApplicable)
      markSupport(Android, example, action, Planned)
    markSupport(Linux, example, "build", Planned) # Building for Linux doesn't work yet

# plainwebview doesn't work on mobile
for action in actions:
  markSupport(MobileDev, "plainwebview", action, NotApplicable)
  markSupport(Android, "plainwebview", action, NotApplicable)
  markSupport(Ios, "plainwebview", action, NotApplicable)
  markSupport(IosSimulator, "plainwebview", action, NotApplicable)

suite "checks":
  for example in example_dirs:
    for target in buildTargets:
      var main_file = ""
      var args: seq[string]
      case target
      of Windows:
        main_file = desktopMain(example)
        args.add @["--os:windows", "-d:appName=test.app"]
      of Mac:
        main_file = desktopMain(example)
        args.add @["--os:macosx", "-d:appName=test.app"]
      of Linux:
        main_file = desktopMain(example)
        args.add "--os:linux"
      of Android:
        main_file = mobileMain(example)
        args.add @["--os:linux", "-d:android", "--noMain", "--threads:on", "--gc:orc"]
      of Ios,IosSimulator:
        main_file = mobileMain(example)
        args.add @["--os:macosx", "-d:ios", "--threads:on", "--gc:orc", "-d:appBundleIdentifier=test.app"]
      of MobileDev:
        main_file = mobileMain(example)
        args.add @["-d:wiish_mobiledev", "--gc:orc"]
      else:
        raise ValueError.newException("Unsupported build target: " & $target)
      if main_file != "":
        test($target & " " & example.extractFilename):
          var cmd = @["nim", "check", "--hints:off", "-d:testconcepts"]
          cmd.add args
          cmd.add(main_file)
          let cmdstr = cmd.join(" ")
          checkpoint "COMMAND: " & cmdstr
          check execCmd(cmdstr) == 0
  
const run_sentinel = "WIISH RUN STARTING"

var outChan: Channel[string]
outChan.open()

proc readOutput(s: Stream) {.thread.} =
  var line: string
  try:
    while s.readLine(line):
      debug line
      outChan.send(line & "\l")
  except:
    warn "Ignoring error reading line: ", getCurrentExceptionMsg()

proc waitForDeath(p: Process) =
  for i in 0..10:
    if i > 0: sleep(1000)
    try:
      debug "  terminating pid: ", $p.processID()
      p.terminate()
      debug "  terminated  pid: ", $p.processID()
    except:
      discard
    if not p.running():
      break
  for i in 0..10:
    if i > 0: sleep(1000)
    try:
      debug "  killing pid: ", $p.processID()
      p.kill()
      debug "  killed  pid: ", $p.processID()
    except:
      discard
    if not p.running():
      break
  debug "  waiting for finish: ", $p.processID()
  discard p.waitForExit()
  debug "  closing process: ", $p.processID()
  p.close()
  debug "  done: ", $p.processID()

proc testWiishRun(dirname: string, args: seq[string], sleepSeconds = 5): bool =
  ## Test a `wiish run` invocation
  info "    Running command:"
  info "        cd ", dirname
  let wiishbin = ("bin"/"wiish").absolutePath
  info "        " & wiishbin & " ", args.join(" ")
  withDir dirname:
    echo "about to go"
    var p = startProcess(wiishbin, args = args, options = {poStdErrToStdOut})
    defer: p.close()
    let outs = p.outputStream()
    var readerThread: Thread[Stream]
    readerThread.createThread(readOutput, outs)
    echo "started readerThread"
    var buf: string
    while true:
      echo "while true:"
      if p.running():
        echo "running true"
        # still running
        try:
          echo "waiting to receive line..."
          let line = outChan.recv()
          echo "got line: ", line
          buf.add line
          if run_sentinel in line:
            break
        except:
          warn "Error reading subprocess output"
          warn getCurrentExceptionMsg()
          info buf
          raise
      else:
        echo "early exit"
        warn "wiish command exited prematurely"
        break
    info &"    Waiting for {sleepSeconds}s to see if it keeps running..."
    for i in 0..<sleepSeconds:
      if not p.running():
        break
      sleep(1000)
    result = p.running() # it should still be running
    terminateAllChildren(p.processID())
    debug "waiting for death"
    p.waitForDeath()
    debug "waiting for reader thread..."
    readerThread.joinThread()
    debug "clearing out reader channel..."
    while true:
      let tried = outChan.tryRecv()
      if tried.dataAvailable:
        buf.add tried.msg
      else:
        break
    if not result:
      info buf

var wiish_bin_built = false
proc ensureWiishBin() =
  if not wiish_bin_built:
    info "Building wiish binary..."
    sh "nimble", "build"
    wiish_bin_built = true

suite "run":
  setup:
    ensureWiishBin()

  tearDown:
    let cmd = @["git", "clean", "-X", "-d", "-f", "--", "examples"]
    try:
      sh cmd
    except:
      warn "Error ^ while running: ", cmd.join(" ")

  for example in example_dirs:
    # Desktop
    if desktopMain(example) != "":
      test(example.extractFilename):
        runMaybe:
          forMatrix(THISOS, example.extractFilename, "run"):
            doAssert testWiishRun(example, @["run"], 5)
    
    # Mobile
    if mobileMain(example) != "":
      for targetOS in buildTargets:
        if targetOS in {Android, Ios, IosSimulator, MobileDev}:
          test($targetOS & " " & example.extractFilename):
            if targetOS == Android and not existsEnv("WIISH_RUN_ANDROID"):
              skipReason "set WIISH_RUN_ANDROID=1 to run this test"
            else:
              runMaybe:
                forMatrix(targetOS, example.extractFilename, "run"):
                  var args = @["run"]
                  case targetOS
                  of Android:
                    args.add(@["--os", "android"])
                  of Ios,IosSimulator:
                    args.add(@["--os", "ios-simulator"])
                  of MobileDev:
                    args.add(@["--os", "mobiledev"])
                  else:
                    discard
                  doAssert testWiishRun(example, args, 15)

suite "build":
  tearDown:
    let cmd = @["git", "clean", "-X", "-d", "-f", "--", "examples"]
    try:
      sh cmd
    except:
      warn "Error ^ while running: ", cmd.join(" ")

  for example in example_dirs:
    # Desktop
    if desktopMain(example) != "":
      test(example.extractFilename):
        withDir example:
          forMatrix(THISOS, example.extractFilename, "build"):
            runWiish "build"
    
    # Mobile
    if mobileMain(example) != "":
      if IosSimulator in buildTargets:
        test("ios-simulator " & example.extractFilename):
          withDir example:
            forMatrix(IosSimulator, example.extractFilename, "build"):
              runWiish "build", "--os", "ios-simulator", "--target", "ios-app"
            
      
      if Android in buildTargets:
        test("android " & example.extractFilename):
          androidBuildMaybe:
            withDir example:
              forMatrix(Android, example.extractFilename, "build"):
                runWiish "build", "--os", "android"

suite "init":
  setup:
    let cmd = @["git", "clean", "-X", "-d", "-f", "--", "examples"]
    try:
      sh cmd
    except:
      warn "Error ^ while running: ", cmd.join(" ")

  test "init and build":
    withDir tmpDir():
      info absolutePath"."
      addConfigNims()
      runWiish "init", "desktop"
      withDir "desktop":
        runWiish "build"
  
  if Ios in buildTargets or IosSimulator in buildTargets:
    test "init and build --os ios-simulator":
      withDir tmpDir():
        info absolutePath"."
        addConfigNims()
        runWiish "init", "iostest"
        withDir "iostest":
          runWiish "build", "--os", "ios-simulator", "--target", "ios-app"

  if Android in buildTargets:  
    test "init and build --os android":
      androidBuildMaybe:
        withDir tmpDir():
          info absolutePath"."
          addConfigNims()
          runWiish "init", "androidtest"
          withDir "androidtest":
            runWiish "build", "--os", "android"

stdout.flushFile()
stderr.flushFile()

info "\n## Support Matrix for " & $THISOS
displaySupport(THISOS)
