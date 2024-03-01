# Package
version       = "0.5.0"
author        = "Matt Haggard"
description   = "Why Is It So Hard to make a cross platform app?"
license       = "MIT"

srcDir        = "."
namedBin      = {"wiishcli":"wiish"}.toTable()
binDir        = "bin"
installDirs   = @["wiish", "examples"]

# Dependencies
requires "nim >= 1.0.6"
requires "argparse >= 2.0.0 & < 3.0.0"
requires "jnim = 0.5.1"
requires "regex >= 0.18.0 & < 1.0.0"
requires "chronos >= 3.0.0 & < 4.0.0"

# Graphics dependencies
requires "webview"
requires "https://github.com/yglukhov/darwin"
requires "pixie"