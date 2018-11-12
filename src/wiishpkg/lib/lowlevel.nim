## Module of low level windowing and event handling stuff
import sequtils
import os
import ospaths
import ../events
import ../defs
import ./logging
import ./wiishtypes


# template start*(app:Application)
proc quit*(app: Application)
proc newSDLWindow*(app: Application, title:string = ""): Window
proc newGLWindow*(app: Application, title:string = ""): Window
proc resourcePath*(app: Application, filename: string): string


when defined(wiishDev):
  import ../building/config
  proc resourcePath*(app: Application, filename: string): string =
    ## Return the path to a static resource included in the application
    let
      appdir = getAppDir()
      configPath = appdir/"wiish.toml"
      config = getMyOSConfig(configPath)
    result = joinPath(config.resourceDir, filename) # XXX this is not safe from going above resourcePath
else:
  proc resourcePath*(app: Application, filename: string): string =
    ## Return the path to a static resource included in the application
    let
      root = 
        when defined(ios):
          getAppDir()/"static"
        elif defined(android):
          getAppDir()
        elif defined(macosx):
          getAppDir()/"../Resources/resources"
        else:
          getAppDir()
    result = joinPath(root, filename) # XXX this is not safe from going above resourcePath


include ./loops/sdlloop

