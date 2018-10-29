import sequtils
import ./events
import ./logging
import os
export events

import ./wiishtypes
export wiishtypes

proc start*(app:App)
proc quit*(app:App)
proc newWindow*():Window

when defined(macosx) and not defined(ios):
  include ./loops/macos
else:
  include ./loops/glfwloop

