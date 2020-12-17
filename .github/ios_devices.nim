import json
import strutils
import osproc

let output = execCmdEx("xcrun simctl list devices 'iphone 11' --json").output
stderr.write(output)
let data = output.parseJson()
let devices = data["devices"]
var ios_devices:JsonNode
for k,v in devices.pairs():
  if ".iOS" in k:
    ios_devices = v
    break

for item in ios_devices:
  if item["isAvailable"].getBool(false):
    echo item["udid"].getStr()
