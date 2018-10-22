import os
import parsetoml
import ./macos

const default_icon = slurp"./data/default.png"


proc doBuild*(directory:string = ".", macos:bool = false) =
  let config_file = directory/"wiish.toml"
  echo "config_file: ", config_file
  let config = parsetoml.parseFile(config_file)
  if macos:
    doMacBuild(directory, config)

proc doRun*(directory:string = ".") =
  let config_file = directory/"wiish.toml"
  echo "config_file: ", config_file
  let config = parsetoml.parseFile(config_file)
  when defined(macosx):
    doMacRun(directory, config)
