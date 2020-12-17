import json
import strutils
import osproc

let output = execCmdEx("xcrun simctl list devices 'iphone 11' --json").output
let data = output.parseJson()
let devices = data["devices"]
for k,v in devices.pairs():
  if ".iOS" in k:
    for item in v:
      if item["isAvailable"].getBool(false):
        echo item["udid"].getStr()
  
