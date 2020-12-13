import distros
import os
import osproc
import strformat
import strutils
import tables

import wiish/building/buildutil
import wiish/doctor

proc checkDoctor*(): seq[DoctorResult] =
  var libs = [
    ("SDL2", true),
    ("SDL2_ttf", false),
    ("SDL2_image", false),
    ("SDL2_gfx", false),
  ]
  for (name, required) in libs:
    result.dr "sdl2", "lib" & name:
      when defined(macosx):
        dr.targetOS = {Mac}
        if not fileExists("/usr/local/lib" / "lib" & name & ".dylib"):
          if required:
            dr.status = NotWorking
          else:
            dr.status = NotWorkingButOptional
          dr.error = &"Missing the {name} dynamic library"
          dr.fix = &"Maybe this will work:\l\l  brew install {name.toLower()}"
      elif defined(windows):
        dr.targetOS = {Windows}
        if required:
          dr.status = NotWorking
        else:
          dr.status = NotWorkingButOptional
        dr.error = "Unable to check if library is present"
      else:
        let installNames = {
          "SDL2": "libsdl2-dev",
          "SDL2_ttf": "libsdl2-ttf-dev",
          "SDL2_image": "libsdl2-image-dev",
          "SDL2_gfx": "libsdl2-gfx-dev",
        }.toTable()
        dr.targetOS = {Linux}
        if execCmdEx("pkg-config --cflags " & name).exitCode != 0:
          if required:
            dr.status = NotWorking
          else:
            dr.status = NotWorkingButOptional
          dr.error = &"Missing library {name}"
          dr.fix = "Maybe this will work:\l\l  "
          let cmd = foreignDepInstallCmd(installNames.getOrDefault(name, name))
          if cmd[1]:
            dr.fix.add "sudo "
          dr.fix.add cmd[0]
