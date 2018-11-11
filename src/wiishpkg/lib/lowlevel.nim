## Module of low level windowing and event handling stuff
import sequtils
import ../events
import ../defs
import ./logging
import os
import ./wiishtypes


# template start*(app:Application)
proc quit*(app: Application)
# proc newSDLWindow*(app: Application, title:string = ""): Window
proc newGLWindow*(app: Application, title:string = ""): Window

include ./loops/sdlloop
