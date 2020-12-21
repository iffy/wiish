# Package
version       = "0.1.0"
author        = "Matt Haggard"
description   = "Why Is It So Hard to make a cross platform app?"
license       = "MIT"

srcDir        = "."
namedBin      = {"wiishcli":"wiish"}.toTable()
binDir        = "bin"
installDirs   = @["wiish", "examples"]

# Dependencies
requires "nim >= 1.0.6"
requires "parsetoml >= 0.3.2"
requires "argparse >= 2.0.0 & < 3.0.0"
requires "jnim >= 0.5"
requires "regex >= 0.18.0 & < 1.0.0"

# Graphics dependencies
requires "opengl >= 1.2.1"
requires "webview"
# requires "glfw >= 0.1.0"
requires "sdl2 >= 2.0.1 & < 3.0.0"
requires "https://github.com/yglukhov/darwin"
requires "vmath >= 0.3.2 & < 0.4.0"
requires "chroma >= 0.1.5 & < 0.2.0"
requires "flippy >= 0.4.7 & < 1.0.0"