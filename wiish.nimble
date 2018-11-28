# Package
version       = "0.1.0-dev"
author        = "Matt Haggard"
description   = "Why Is It So Hard to make a cross platform app?"
license       = "MIT"
# binDir        = "bin"
# srcDir        = "src"
skipDirs      = @["dist"]
installDirs   = @["wiishpkg", "examples"]
bin           = @["wiish"]

# Dependencies

requires "nim >= 0.19.0"
requires "parsetoml >= 0.3.2"
# requires "argparse >= 0.2.0"
requires "https://github.com/iffy/nim-argparse.git"
# requires "https://github.com/mjendrusch/objc.git"

# Graphics dependencies
requires "opengl"
requires "webview"
# requires "glfw >= 0.1.0"
requires "https://github.com/Vladar4/sdl2_nim.git#master" # nimble install https://github.com/Vladar4/sdl2_nim.git@#master
# requires "nanovg >= 0.1"
requires "https://github.com/yglukhov/darwin"
# requires "nimx"
