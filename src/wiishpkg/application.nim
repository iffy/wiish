import sequtils
import ./events
import ./logging
import os
export events

import ./wiishtypes
export wiishtypes

proc start*(app:App)
proc quit*(app:App)
proc newWindow*(title:string = ""):Window

when macDesktop:
  include ./loops/macos
else:
  include ./loops/glfwloop

