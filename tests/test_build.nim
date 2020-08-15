import unittest
import os
import strformat
import random
import wiish/building/config
import wiish/building/build
import wiish/building/buildutil

randomize()

proc tmpDir(): string {.used.} =
  os.getTempDir() / &"wiishtest{random.rand(10000000)}"

proc pathToWiishRoot(): string =
  currentSourcePath.absolutePath.parentDir.parentDir

suite "build":
  # Build all the examples/
  for example in walkDir(currentSourcePath.parentDir.parentDir/"examples"):
    if example.kind == pcDir:
      # Desktop example apps
      if (example.path/"main_desktop.nim").fileExists:
        test("build examples/" & example.path.extractFilename):
          doBuild(example.path)
      
      # Mobile example apps
      if (example.path/"main_mobile.nim").fileExists:
        test("build --target ios examples/" & example.path.extractFilename):
          when defined(macosx):
            var config = parseConfig(example.path/"wiish.toml")
            config.override($IsSimulator, true)
            doBuild(example.path, target = Ios, config)
          else:
            skip
        test("build --target android examples/" & example.path.extractFilename):
          if existsEnv("WIISH_BUILD_ANDROID"):
            doBuild(example.path, target = Android)
          else:
            skip

  test "init and build":
    let tmpdir = tmpDir()
    echo &"Testing inside: {tmpdir}"
    doInit(tmpdir, "sdl2")
    # hack the path
    let path_to_wiishroot = pathToWiishRoot()
    writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiishroot}")""")
    doBuild(tmpdir)
    
  test "init and build iOS":
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
      skip
  
  test "init and build android":
    if not existsEnv("WIISH_BUILD_ANDROID"):
      skip
    else:
      let tmpdir = tmpDir()
      echo &"Testing inside: {tmpdir}"
      doInit(tmpdir, "webview")
      # hack the path
      let path_to_wiishroot = pathToWiishRoot()
      writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiishroot}")""")
      doBuild(tmpdir, target = Android)
