import unittest
import os
import ospaths
import wiishpkg/build

when defined(macosx):
  suite "macos":
    test "build":
      let directory = (currentSourcePath.parentDir/"../examples/basicmac").normalizedPath
      doBuild(directory, macos = true)
    
    test "run":
      when defined(runapps):
        let directory = (currentSourcePath.parentDir/"../examples/basicmac").normalizedPath
        doRun(directory)
      else:
        skip