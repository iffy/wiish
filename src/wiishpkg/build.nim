import os
import strformat
import parsetoml
import ./macos
import ./config

const default_icon = slurp"./data/default.png"
const sample_toml = slurp"./data/sample.toml"
const sample_app = slurp"./data/sampleapp.nim"


proc doBuild*(directory:string = ".", macos:bool = false) =
  let config = readConfig(directory/"wiish.toml")
  if macos:
    doMacBuild(directory, config)

proc doRun*(directory:string = ".") =
  let config = readConfig(directory/"wiish.toml")
  when defined(macosx):
    doMacRun(directory, config)

proc doInit*(directory:string = ".") =
  directory.createDir()
  let conf_file = directory/"wiish.toml"
  if not conf_file.fileExists:
    writeFile(directory/"wiish.toml", sample_toml)
    echo &"wrote {conf_file}"
  let app_nim = directory/"app.nim"
  if not app_nim.fileExists:
    writeFile(app_nim, sample_app)
    echo &"wrote {app_nim}"
  echo &"""Initialized a new wiish app in {directory}

Run:    wiish run {directory}
Build:  wiish build {directory} --mac
"""