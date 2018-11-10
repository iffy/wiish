import unittest
import os
import strformat
import random
import ospaths
import wiishpkg/building/build
import wiishpkg/building/buildutil

randomize()

proc tmpDir():string =
  os.getTempDir() / &"wiishtest{random.rand(10000000)}"

suite "build":
  # Build all the examples/
  for example in walkDir(currentSourcePath.parentDir.parentDir/"examples"):
    if example.kind == pcDir:
      test("build examples/" & example.path.basename):
        doBuild(example.path)
      when defined(macosx):
        test("build --ios examples/" & example.path.basename):
          doBuild(example.path, ios = true)

  test "init and build":
    let tmpdir = tmpDir()
    echo &"Testing inside: {tmpdir}"
    doInit(tmpdir)
    # hack the path
    let path_to_wiish_src = currentSourcePath.absolutePath.parentDir.parentDir/"src"
    writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiish_src}")""")
    doBuild(tmpdir)
    
  when defined(macosx):
    test "init and build iOS":
      let tmpdir = tmpDir()
      echo &"Testing inside: {tmpdir}"
      doInit(tmpdir)
      # hack the path
      let path_to_wiish_src = currentSourcePath.absolutePath.parentDir.parentDir/"src"
      writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiish_src}")""")
      doBuild(tmpdir, ios = true)
