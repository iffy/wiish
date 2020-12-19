import os
import std/exitprocs
import strformat
import strutils
import terminal
import times
import unittest

type
  MyFormatter = ref object of OutputFormatter
    startTime: DateTime
    currentSuite: string
    currentTest: string
    currentSkip: string
    progResult: int
    lastStdout: int64
    lastStderr: int64
    failedTests: seq[string]
    skippedTests: seq[string]
    okTests: int
  
  SkipTestError* = object of CatchableError

proc newMyFormatter(): MyFormatter =
  MyFormatter(startTime: now())

proc mkPreline(suiteName: string, testName: string, prefix = ""): string =
  result.add prefix
  if suiteName != "":
    result.add suiteName & "::"
  result.add testName & " "

method suiteStarted*(formatter: MyFormatter, suiteName: string) =
  formatter.currentSuite = suiteName
  stdout.styledWriteLine styleBright, "=".repeat(terminalWidth())
  stdout.styledWriteLine styleBright, suiteName & "::"

method testStarted*(formatter: MyFormatter, testName: string) =
  var preline = mkPreline(formatter.currentSuite, testName, prefix = "START ")
  stdout.styledWrite styleDim, preline
  stdout.flushFile()
  try:
    formatter.lastStdout = stdout.getFilePos()
    formatter.lastStderr = stderr.getFilePos()
  except:
    discard

method failureOccurred*(formatter: MyFormatter, checkpoints: seq[string], stackTrace: string) =
  if "[SkipTestError]" in checkpoints[^1]:
    # this is kind of a hack because of unittest
    var msg = checkpoints[^1]
    if msg.startsWith("Unhandled exception: "):
      msg = msg.substr("Unhandled exception: ".len)
    msg = msg.substr(0, msg.len - " [SkipTestError]".len)
    formatter.currentSkip = msg
  else:
    if formatter.progResult != 0:
      echo &"EXITCODE=1 for {formatter.currentSuite}::{formatter.currentTest}"
    formatter.progResult = 1
    stdout.styledWriteLine fgRed, "\nFAILURE >>>"
    for item in checkpoints:
      stdout.writeLine(item)
    stdout.writeLine(stackTrace)

method testEnded*(formatter: MyFormatter, testResult: TestResult) =
  var bytesWritten:int64 = 1
  try:
    bytesWritten = stdout.getFilePos() - formatter.lastStdout + stderr.getFilePos() - formatter.lastStderr
  except:
    discard
  if bytesWritten == 0:
    stdout.write "\r"
  else:
    stdout.writeLine ""
  let preline = mkPreline(testResult.suiteName, testResult.testName, prefix = "")
  # stdout.write preline
  
  var fullname = ""
  if testResult.suiteName != "":
    fullname.add testResult.suiteName & "::"
  fullname.add testResult.testName

  var status = testResult.status
  if formatter.currentSkip != "":
    status = SKIPPED
  
  case status
  of OK:
    stdout.styledWrite fgGreen, "[OK] "
    stdout.writeLine preline
    formatter.okTests.inc()
  of FAILED:
    stdout.styledWrite fgRed, "[FAILED] "
    stdout.writeLine preline
    formatter.failedTests.add fullname
    formatter.progResult = 1
  of SKIPPED:
    stdout.styledWrite fgYellow, "[SKIPPED] "
    stdout.write preline
    stdout.styledWriteLine styleDim, " ", formatter.currentSkip
    formatter.skippedTests.add fullname
  if bytesWritten > 0:
    echo "-".repeat(terminalWidth())
  formatter.currentTest = ""
  formatter.currentSkip = ""

method suiteEnded*(formatter: MyFormatter) = 
  formatter.currentSuite = ""

proc doSkip*(reason: string) =
  raise SkipTestError.newException(reason)

proc summary*(formatter: MyFormatter): string =
  if formatter.skippedTests.len > 0:
    result.add $formatter.skippedTests.len & " skipped, "
  result.add $formatter.okTests & " ok"
  if formatter.failedTests.len > 0:
    result.add ", " & $formatter.failedTests.len & " failed"
  result.add " (" & $(now() - formatter.startTime).inSeconds() & "s)"

proc useCustomUnittestFormatter*() =
  var formatter = newMyFormatter()
  addOutputFormatter(formatter)
  addExitProc proc() =
    if formatter.skippedTests.len > 0:
      echo "SKIPPED TESTS:"
      for name in formatter.skippedTests:
        echo "  ", name
    if formatter.failedTests.len > 0:
      echo "FAILED TESTS:"
      for name in formatter.failedTests:
        echo "  ", name
    echo formatter.summary()
    setProgramResult formatter.progResult
