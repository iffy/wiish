import os
import strformat
import strutils
import tables
import distros
import osproc

import wiish/building/buildutil
import wiish/doctor


type
  Library = enum
    sdl2
    sdl2_ttf
    sdl2_image
    sdl2_gfx
    pkgconfig

proc name(lib: Library): string =
  ## Return the OS-specific name for the library
  if detectOs(MacOSX):
    case lib
    of sdl2: "SDL2"
    of sdl2_ttf: "SDL2_ttf"
    of sdl2_image: "SDL2_image"
    of sdl2_gfx: "SDL2_gfx"
    of pkgconfig: "pkg-config"
  elif detectOs(ArchLinux):
    case lib
    of sdl2: "sdl2"
    of sdl2_ttf: "SDL_ttf"
    of sdl2_image: "SDL_image"
    of sdl2_gfx: "SDL_gfx"
    of pkgconfig: "pkg-config"
  else:
    # Ubuntu is the default
    case lib
    of sdl2: "sdl2"
    of sdl2_ttf: "SDL2_ttf"
    of sdl2_image: "SDL2_image"
    of sdl2_gfx: "SDL2_gfx"
    of pkgconfig: "pkg-config"

proc install_pkg(lib: Library): string =
  ## Return the package you need to install to get the given libname
  if detectOs(MacOSX):
    case lib
    of sdl2: "sdl2"
    of sdl2_ttf: "sdl2_ttf"
    of sdl2_image: "sdl2_image"
    of sdl2_gfx: "sdl2_gfx"
    of pkgconfig: "pkg-config"
  elif detectOs(ArchLinux):
    case lib
    of sdl2: "sdl2"
    of sdl2_ttf: "sdl_ttf"
    of sdl2_image: "sdl_image"
    of sdl2_gfx: "sdl_gfx"
    of pkgconfig: "pkgconf"
  else:
    # Ubuntu is the default
    case lib
    of sdl2: "libsdl2-dev"
    of sdl2_ttf: "libsdl2-ttf-dev"
    of sdl2_image: "libsdl2-image-dev"
    of sdl2_gfx: "libsdl2-gfx-dev"
    of pkgconfig: "pkg-config"


proc checkDoctor*(): seq[DoctorResult] =
  when defined(windows):
    result.dr "sdl2", "libSDL2":
      dr.status = NotWorkingButOptional
      dr.error = &"Wiish currently can't detect if libSDL2 is installed on Windows"
      dr.fix = &"Submit a PR to github.com/iffy/wiish with tips on how to do this on Windows."
  else:
    var has_pkgconfig = false
    result.dr "sdl2", "pkg-config":
      dr.targetOS = {Linux, Mac}
      if findExe"pkg-config" == "":
        dr.status = NotWorking
        dr.error = &"Missing pkg-config"
        dr.fix = "Maybe this will work:\l\l"
        let cmd = foreignDepInstallCmd(pkgconfig.install_pkg)
        if cmd[1]:
          dr.fix.add "sudo "
        dr.fix.add cmd[0]
      else:
        has_pkgconfig = true

    var libs = [
      (sdl2, true),
      (sdl2_ttf, false),
      (sdl2_image, false),
      (sdl2_gfx, false),
    ]
    for (library, required) in libs:
      result.dr "sdl2", library.name:
        dr.targetOS = {Linux, Mac}
        if execCmdEx("pkg-config --cflags " & library.name).exitCode != 0:
          if required:
            dr.status = NotWorking
          else:
            dr.status = NotWorkingButOptional
          if not has_pkgconfig:
            dr.error = &"Unable to run pkg-config"
            dr.fix = "See instructions for fixing sdl2/pkg-config first"
          else:
            dr.error = &"Missing library {library.name}"
            dr.fix = "Maybe this will work:\l\l"
            let cmd = foreignDepInstallCmd(library.install_pkg)
            if cmd[1]:
              dr.fix.add "sudo "
            dr.fix.add cmd[0]
