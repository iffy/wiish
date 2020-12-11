import algorithm
import os
import osproc
import random
import sequtils
import streams
import strformat
import strutils
import tables
import terminal
import unittest
import std/compilesettings

import wiish/building/buildutil
import wiishcli

randomize()

const example_dirs = toSeq(walkDir(currentSourcePath.parentDir.parentDir/"examples")).filterIt(it.kind == pcDir).mapIt(it.path).sorted()
const examples = example_dirs.mapIt(it.extractFilename())
let VERBOSE = getEnv("VERBOSE") != ""

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
  ## Recursively terminate all child processes.
  when defined(macosx) or defined(linux):
    while true:
      let children = listAllChildPids(pid)
      if children.len == 0:
        break
      for child in children:
        try:
          discard shoutput("kill", $child)
        except:
          discard

#---------------------------------------------------------------
# Support Tables
#---------------------------------------------------------------
type
  SupportStatus = enum
    NotWorking
    NotApplicable
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

const actions = ["run", "build"]

proc str(status: SupportStatus): string =
  case status
  of NotWorking:
    "X"
  of NotApplicable:
    "-"
  of Working:
    "OK"

proc displaySupport() =
  var rows:seq[seq[string]]
  var col1max = 0
  var col2max = 0
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
      rows.add @[$targetOS, example, run_status.str(), build_status.str()]
      col1max = max(col1max, rows[^1][0].len)
      col2max = max(col2max, rows[^1][1].len)
  proc pad(x: string, size: int): string =
    result.add x
    if x.len < size:
      result.add " ".repeat(size - x.len)
  for row in rows:
    stdout.styledWrite "| " & row[0].pad(col1max)
    stdout.styledWrite " | " & row[1].pad(col2max)
    stdout.styledWrite " | " & row[2].pad(2)
    stdout.styledWrite " | " & row[3].pad(2)
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

elif defined(windows):
  const THISOS = Windows
  const buildTargets = {Windows, Android, MobileDev}
  for example in examples:
    for action in actions:
      markSupport(Mac, example, action, NotApplicable)
      markSupport(Ios, example, action, NotApplicable)
      markSupport(IosSimulator, example, action, NotApplicable)
      markSupport(Linux, example, action, NotApplicable)

else:
  const THISOS = Linux
  const buildTargets = {Linux, Android, MobileDev}
  for example in examples:
    for action in actions:
      markSupport(Mac, example, action, NotApplicable)
      markSupport(Ios, example, action, NotApplicable)
      markSupport(IosSimulator, example, action, NotApplicable)
      markSupport(Windows, example, action, NotApplicable)


suite "checks":
  for example in example_dirs:
    for target in buildTargets:
      var main_file = ""
      var args: seq[string]
      case target
      of Windows:
        main_file = "main_desktop.nim"
        args.add "--os:windows"
      of Mac:
        main_file = "main_desktop.nim"
        args.add "--os:macosx"
      of Linux:
        main_file = "main_desktop.nim"
        args.add "--os:linux"
      of Android:
        main_file = "main_mobile.nim"
        args.add @["--os:linux", "-d:android", "--noMain", "--threads:on", "--gc:orc"]
      of Ios,IosSimulator:
        main_file = "main_mobile.nim"
        args.add @["--os:macosx", "-d:ios", "--threads:on", "--gc:orc"]
      of MobileDev:
        main_file = "main_mobile.nim"
        args.add @["-d:wiish_mobiledev", "--gc:orc"]
      else:
        raise ValueError.newException("Unsupported build target: " & $target)
      if fileExists example/main_file:
        vtest($target & " " & example.extractFilename):
          var cmd = @["nim", "check", "--hints:off", "-d:testconcepts"]
          cmd.add args
          cmd.add(example / main_file)
          let cmdstr = cmd.join(" ")
          checkpoint "COMMAND: " & cmdstr
          check execCmd(cmdstr) == 0

const run_sentinel = "WIISH RUN STARTING"

var outChan: Channel[string]
outChan.open()

proc readOutput(s: Stream) {.thread.} =
  while not s.atEnd():
    try:
      let line = s.readLine()
      if VERBOSE:
        stderr.writeLine line
      outChan.send(line & "\l")
    except:
      break

proc testWiishRun(dirname: string, args: seq[string], sleepSeconds = 5): bool =
  ## Test a `wiish run` invocation
  echo "    Running command:"
  echo "        cd ", dirname
  let wiishbin = ("bin"/"wiish").absolutePath
  echo "        " & wiishbin & " ", args.join(" ")
  withDir dirname:
    var p = startProcess(wiishbin, args = args, options = {poStdErrToStdOut})
    defer: p.close()
    let outs = p.outputStream()
    var readerThread: Thread[Stream]
    readerThread.createThread(readOutput, outs)

    var buf: string
    while true:
      let rc = p.peekExitCode()
      if rc == -1:
        # still running
        try:
          let line = outChan.recv()
          buf.add line
          if run_sentinel in line:
            break
        except:
          echo "Error reading stderr"
          echo getCurrentExceptionMsg()
          echo buf
          raise
      elif rc == 0:
        # quit
        assert false, "wiish run exited prematurely"
      else:
        assert false, "wiish run failed"
    echo &"    Waiting for {sleepSeconds}s to see if it keeps running..."
    for i in 0..<sleepSeconds:
      if p.peekExitCode() != -1:
        break
      sleep(1000)
    result = p.peekExitCode() == -1 # it should still be running
    terminateAllChildren(p.processID())
    discard p.waitForExit()
    readerThread.joinThread()
    while true:
      let tried = outChan.tryRecv()
      if tried.dataAvailable:
        buf.add tried.msg
      else:
        break
    if not result and not VERBOSE:
      echo buf

var already_built = false

suite "run":
  setup:
    if not already_built:
      echo "Building wiish binary..."
      sh "nimble", "build"
      already_built = true

  tearDown:
    let cmd = @["git", "clean", "-X", "-d", "-f", "--", "examples"]
    try:
      sh cmd
    except:
      echo "Error ^ while running: ", cmd.join(" ")

  for example in example_dirs:
    # Desktop
    if fileExists example/"main_desktop.nim":
      vtest(example.extractFilename):
        runMaybe:
          if testWiishRun(example, @["run"], 5):
            markSupport(THISOS, example.extractFilename, "run", Working)
          else:
            check false
    
    # Mobile
    if fileExists example/"main_mobile.nim":
      for name in buildTargets:
        # if name in {Android, Ios, IosSimulator, MobileDev}:
        if name in {Android}:
          vtest($name & " " & example.extractFilename):
            runMaybe:
              var args = @["run"]
              case name
              of Android:
                args.add(@["--os", "android"])
              of Ios,IosSimulator:
                args.add(@["--os", "ios-simulator"])
              of MobileDev:
                args.add(@["--os", "mobiledev"])
              else:
                discard
              if testWiishRun(example, args, 15):
                markSupport(name, example.extractFilename, "run", Working)
              else:
                check false

suite "build":
  tearDown:
    let cmd = @["git", "clean", "-X", "-d", "-f", "--", "examples"]
    try:
      sh cmd
    except:
      echo "Error ^ while running: ", cmd.join(" ")

  for example in example_dirs:
    # Desktop
    if fileExists example/"main_desktop.nim":
      vtest("desktop " & example.extractFilename):
        withDir example:
          runWiish "build"
          markSupport(THISOS, example.extractFilename, "build", Working)
    
    # Mobile
    if fileExists example/"main_mobile.nim":
      if IosSimulator in buildTargets:
        vtest("ios-simulator " & example.extractFilename):
          withDir example:
            runWiish "build", "--os", "ios-simulator", "--target", "ios-app"
            markSupport(IosSimulator, example.extractFilename, "build", Working)
      
      if Android in buildTargets:
        vtest("android " & example.extractFilename):
          androidMaybe:
            withDir example:
              runWiish "build", "--os", "android"
              markSupport(Android, example.extractFilename, "build", Working)

suite "init":
  setup:
    let cmd = @["git", "clean", "-X", "-d", "-f", "--", "examples"]
    try:
      sh cmd
    except:
      echo "Error ^ while running: ", cmd.join(" ")

  vtest "init and build":
    withDir tmpDir():
      echo absolutePath"."
      addConfigNims()
      runWiish "init", "desktop"
      withDir "desktop":
        runWiish "build"
  
  if Ios in buildTargets or IosSimulator in buildTargets:
    vtest "init and build --os ios-simulator":
      withDir tmpDir():
        echo absolutePath"."
        addConfigNims()
        runWiish "init", "iostest"
        withDir "iostest":
          runWiish "build", "--os", "ios-simulator", "--target", "ios-app"

  if Android in buildTargets:  
    vtest "init and build --os android":
      androidMaybe:
        withDir tmpDir():
          echo absolutePath"."
          addConfigNims()
          runWiish "init", "androidtest"
          withDir "androidtest":
            runWiish "build", "--os", "android"

echo "## Support Matrix for " & $THISOS
displaySupport()
