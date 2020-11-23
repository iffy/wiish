import unittest
import terminal
import os
import osproc
import strformat
import strutils
import random
import wiish/building/config
import wiish/building/build
import wiish/building/buildutil

randomize()

proc tmpDir(): string {.used.} =
  os.getTempDir() / &"wiishtest{random.rand(10000000)}"

proc pathToWiishRoot(): string =
  currentSourcePath.absolutePath.parentDir.parentDir

template vtest(name: string, body: untyped): untyped =
  ## Verbosely labeled test
  stderr.styledWriteLine(fgCyan, "  [START] ", name, resetStyle)
  test(name):
    body

template skipReason(reason: string): untyped =
  stderr.styledWriteLine(fgYellow, "  SKIP REASON: " & reason, resetStyle)
  skip

const desktopBuildSetups = [
  ("macos", @["--os:macosx"]),
  ("linux", @["--os:linux"]),
  ("windows", @["--os:windows"]),
]
const mobileBuildSetups = [
  ("ios", @["--os:macosx", "-d:ios", "--threads:on", "--gc:orc"]),
  ("android", @["--os:linux", "-d:android", "--noMain", "--threads:on", "--gc:orc"]),
  ("mobiledev", @["-d:wiish_mobiledev", "--gc:orc"])
]

suite "examples":
  # Build and check all the examples/
  for example in walkDir(currentSourcePath.parentDir.parentDir/"examples"):
    if example.kind == pcDir:
      # Desktop example apps
      if (example.path/"main_desktop.nim").fileExists:
        vtest("build examples/" & example.path.extractFilename):
          doBuild(example.path)
        for (name, args) in desktopBuildSetups:
          vtest("check examples/" & example.path.extractFilename & " " & name):
            var cmd = @["nim", "check", "--hints:off", "-d:testconcepts"]
            cmd.add(args)
            cmd.add(example.path / "main_desktop.nim")
            let cmdstr = cmd.join(" ")
            let rc = execCmd(cmdstr)
            if rc != 0:
              raise ValueError.newException("Error on " & name & ": " & cmdstr)
      
      # Mobile example apps
      if (example.path/"main_mobile.nim").fileExists:
        vtest("build --target ios examples/" & example.path.extractFilename):
          when defined(macosx):
            var config = parseConfig(example.path/"wiish.toml")
            config.override($IsSimulator, true)
            doBuild(example.path, target = Ios, config)
          else:
            skipReason "only builds on macOS"
        vtest("build --target android examples/" & example.path.extractFilename):
          if existsEnv("WIISH_BUILD_ANDROID"):
            doBuild(example.path, target = Android)
          else:
            skipReason "only builds if WIISH_BUILD_ANDROID is set"
        for (name, args) in mobileBuildSetups:
          vtest("check examples/" & example.path.extractFilename & " " & name):
            var cmd = @["nim", "check", "--hints:off", "-d:testconcepts"]
            cmd.add(args)
            cmd.add(example.path / "main_mobile.nim")
            let cmdstr = cmd.join(" ")
            let rc = execCmd(cmdstr)
            if rc != 0:
              raise ValueError.newException("Error on " & name & ": " & cmdstr)

suite "init":

  vtest "init and build":
    let tmpdir = tmpDir()
    echo &"Testing inside: {tmpdir}"
    doInit(tmpdir, "sdl2")
    # hack the path
    let path_to_wiishroot = pathToWiishRoot()
    writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiishroot}")""")
    doBuild(tmpdir)
    
  vtest "init and build iOS":
    when defined(macosx):
      let tmpdir = tmpDir()
      echo &"Testing inside: {tmpdir}"
      doInit(tmpdir, "sdl2")
      # hack the path
      let path_to_wiishroot = pathToWiishRoot()
      writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiishroot}")""")
      var config = parseConfig(tmpdir/"wiish.toml")
      config.override($IsSimulator, true)
      doBuild(tmpdir, target = Ios, config)
    else:
      skipReason "only builds on macOS"
  
  vtest "init and build android":
    if not existsEnv("WIISH_BUILD_ANDROID"):
      skipReason "only builds if WIISH_BUILD_ANDROID is set"
    else:
      let tmpdir = tmpDir()
      echo &"Testing inside: {tmpdir}"
      doInit(tmpdir, "webview")
      # hack the path
      let path_to_wiishroot = pathToWiishRoot()
      writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiishroot}")""")
      doBuild(tmpdir, target = Android)
