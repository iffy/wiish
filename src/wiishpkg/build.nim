import os
import parsetoml
import ./macos
import ./config

const default_icon = slurp"./data/default.png"


proc doBuild*(directory:string = ".", macos:bool = false) =
  let config = readConfig(directory/"wiish.toml")
  if macos:
    doMacBuild(directory, config)

proc doRun*(directory:string = ".") =
  let config = readConfig(directory/"wiish.toml")
  when defined(macosx):
    doMacRun(directory, config)
    