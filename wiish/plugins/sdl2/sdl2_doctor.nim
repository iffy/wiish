import distros
import os
import osproc
import strformat
import strutils
import tables

import wiish/building/buildutil
import wiish/doctor

proc checkDoctor*(): seq[DoctorResult] =
  when defined(linux):
    var libs = [
      ("sdl2", "libsdl2-dev", true),
      ("SDL2_ttf", "libsdl2-ttf-dev", false),
      ("SDL2_image", "libsdl2-image-dev", false),
      ("SDL2_gfx", "libsdl2-gfx-dev", false),
    ]
    for (pkgconfig_name, install_name, required) in libs:
      result.dr "sdl2", pkgconfig_name:
        dr.targetOS = {Linux}
        if execCmdEx("pkg-config --cflags " & pkgconfig_name).exitCode != 0:
          if required:
            dr.status = NotWorking
          else:
            dr.status = NotWorkingButOptional
          dr.error = &"Missing library {pkgconfig_name}"
          dr.fix = "Maybe this will work:\l\l"
          let cmd = foreignDepInstallCmd(install_name)
          if cmd[1]:
            dr.fix.add "sudo "
          dr.fix.add cmd[0]
  elif defined(macosx):
    var libs = [
      ("SDL2", true),
      ("SDL2_ttf", false),
      ("SDL2_image", false),
      ("SDL2_gfx", false),
    ]
    for (name, required) in libs:
      result.dr "sdl2", "lib" & name:
        dr.targetOS = {Mac}
        if not fileExists("/usr/local/lib" / "lib" & name & ".dylib"):
          if required:
            dr.status = NotWorking
          else:
            dr.status = NotWorkingButOptional
          dr.error = &"Missing the {name} dynamic library"
          dr.fix = &"Maybe this will work:\l\l  brew install {name.toLower()}"
  elif defined(windows):
    result.dr "sdl2", "libSDL2":
      dr.status = NotWorkingButOptional
      dr.error &"Wiish currently can't detect if libSDL2 is installed on Windows"
      dr.fix = &"Submit a PR to github.com/iffy/wiish with tips on how to do this on Windows."
