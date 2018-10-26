import unittest
import os
import strformat
import random
import ospaths
import wiishpkg/build

randomize()

suite "build":
  test "build":
    echo "currentSourcePath: ", currentSourcePath.repr
    echo "abs: ", currentSourcePath.absolutePath.repr
    let directory = (currentSourcePath.absolutePath.parentDir.parentDir/"examples"/"basic").normalizedPath
    echo "parent: ", currentSourcePath.absolutePath.parentDir.repr
    echo "directory: ", directory.repr
    doBuild(directory)

  test "init and build":
    let tmpdir = os.getTempDir() / &"wiishtest{random.rand(10000000)}"
    echo &"Testing inside: {tmpdir}"
    doInit(tmpdir)
    # hack the path
    let path_to_wiish_src = currentSourcePath.absolutePath.parentDir.parentDir/"src"
    writeFile(tmpdir/"config.nims", &"""switch("path", "{path_to_wiish_src}")""")
    doBuild(tmpdir)
