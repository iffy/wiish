# Package

version       = "0.1.0"
author        = "Matt Haggard"
description   = "Why Is It So Hard to make a cross platform app?"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["wiish"]

# Dependencies

requires "nim >= 0.19.0"
requires "parsetoml >= 0.3.2"
requires "argparse >= 0.1.0" # https://github.com/iffy/nim-argparse.git

requires "https://github.com/mjendrusch/objc.git"

# Graphics dependencies

requires "sdl2 >= 1.2"
requires "nanovg >= 0.1"
