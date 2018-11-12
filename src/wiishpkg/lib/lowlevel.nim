## Module of low level windowing and event handling stuff
import sequtils
import ../events
import ../defs
import ./logging
import os
import ./wiishtypes


# template start*(app:Application)
proc quit*(app: Application)
proc newSDLWindow*(app: Application, title:string = ""): Window
proc newGLWindow*(app: Application, title:string = ""): Window

# proc resourcePath*(app: Application, filename: string): string =
#   if defined(wiishDev):
#     # wiish run

#   else:
#     # Built application
#     if defined(ios):
#       discard
#     elif defined(android):
#       discard
#     elif defined(macosx):
#       discard


include ./loops/sdlloop

