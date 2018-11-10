import unittest
import os
import strformat
import random
import ospaths
import wiishpkg/building/build

randomize()

proc tmpDir():string =
  os.getTempDir() / &"wiishtest{random.rand(10000000)}"

suite "build":
  test "build":
    let directory = currentSourcePath.absolutePath.parentDir.parentDir/"examples"/"helloworld"
    doBuild(directory)

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
