# Package
version       = "0.1.0"
author        = "Matt Haggard"
description   = "Why Is It So Hard to make a cross platform app?"
license       = "MIT"

srcDir        = "src"
installExt    = @["nim"]
bin           = @["wiish"]
# skipDirs      = @["dist"]
# installDirs   = @["wiish", "examples"]

# Dependencies

# requires "nim <= 1.0.6"
requires "nim >= 1.0.6"
requires "parsetoml >= 0.3.2"
requires "argparse >= 1.1.0" # "https://github.com/iffy/nim-argparse.git"
# requires "https://github.com/mjendrusch/objc.git"
requires "jnim >= 0.5"

# Graphics dependencies
requires "opengl >= 1.2.1"
requires "webview"
# requires "glfw >= 0.1.0"
requires "https://github.com/Vladar4/sdl2_nim.git#master" # nimble install https://github.com/Vladar4/sdl2_nim.git@#master
# requires "nanovg >= 0.1"
requires "https://github.com/yglukhov/darwin"
# requires "nimx"
