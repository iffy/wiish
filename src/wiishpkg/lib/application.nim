import sequtils
import ../events
import ../defs
import ./logging
import os
import ./wiishtypes

proc start*(app:App)
proc quit*(app:App)
proc newWindow*(title:string = ""):Window

when macDesktop:
  include ./loops/macos
else:
  include ./loops/glfwloop

export app
