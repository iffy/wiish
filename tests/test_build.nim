import unittest
import os
import strformat
import random
import ospaths
import wiishpkg/build

randomize()

suite "build":
  test "build":
    let directory = (currentSourcePath.parentDir/".."/"examples"/"basic").normalizedPath
    doBuild(directory)

  test "init and build":
    let tmpdir = os.getTempDir() / &"wiishtest{random.rand(10000000)}"
    echo &"Testing inside: {tmpdir}"
    doInit(tmpdir)
    # hack the path
    let path_to_wiish_src = currentSourcePath.absolutePath().parentDir().parentDir()/"src"
    writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiish_src}")""")
    doBuild(tmpdir)
