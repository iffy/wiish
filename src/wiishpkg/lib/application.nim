import sequtils
import ../events
import ../defs
import ./logging
import os
import ./wiishtypes


# template start*(app:App)
proc quit*(app:App)
proc newWindow*(title:string = ""):Window

when defined(ios):
  include ./loops/ios_sdlloop
else:
  include ./loops/sdlloop

export app
