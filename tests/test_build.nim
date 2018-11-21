import unittest
import os
import strformat
import random
import ospaths
import wiishpkg/building/build
import wiishpkg/building/buildutil

randomize()

proc tmpDir(): string {.used.} =
  os.getTempDir() / &"wiishtest{random.rand(10000000)}"

proc pathToWiishRoot(): string =
  currentSourcePath.absolutePath.parentDir.parentDir

suite "build":
  # Build all the examples/
  for example in walkDir(currentSourcePath.parentDir.parentDir/"examples"):
    if example.kind == pcDir:
      test("build examples/" & example.path.basename):
        doBuild(example.path)
      when defined(macosx):
        if (example.path/"main_mobile.nim").fileExists:
          test("build --ios examples/" & example.path.basename):
            doBuild(example.path, ios = true)

  test "init and build":
    let tmpdir = tmpDir()
    echo &"Testing inside: {tmpdir}"
    doInit(tmpdir, "sdl2")
    # hack the path
    let path_to_wiishroot = pathToWiishRoot()
    writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiishroot}")""")
    doBuild(tmpdir)
    
  when defined(macosx):
    test "init and build iOS":
      let tmpdir = tmpDir()
      echo &"Testing inside: {tmpdir}"
      doInit(tmpdir, "sdl2")
      # hack the path
      let path_to_wiishroot = pathToWiishRoot()
      writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiishroot}")""")
      doBuild(tmpdir, ios = true)
