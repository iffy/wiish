import nake
import os
import times
import re
import ospaths
import strformat

proc basename(x:string):string =
  let split = x.splitFile
  result = split.name & split.ext

proc getNextVersion():string =
  let guts = readFile("wiish.nimble")
  if guts =~ re(".*?version\\s*=\\s*\"(.*?)\"", {reMultiLine, reDotAll}):
    var version = matches[0]
    if version.endsWith("-dev"):
      version = version[0..^5]
    return version
  else:
    raise newException(CatchableError, "Version not detected")

template currentDate():string =
  format(now(), "YYYY-MM-dd")

proc combineChanges():string =
  result.add(&"# v{getNextVersion()} - {currentDate()}\L\L")
  var
    news: seq[string]
    fixes: seq[string]
    breaks: seq[string]
    misc: seq[string]
  for thing in os.walkDir(currentSourcePath.parentDir/"changes"):
    if thing.kind == pcFile:
      if thing.path.endsWith(".md"):
        let guts = readFile(thing.path).strip()
        let changetype = thing.path.basename().split("-")[0]
        var tag:string
        case changetype
        of "fix":
          fixes.add(guts)
        of "new":
          news.add(guts)
        of "break":
          breaks.add(guts)
        else:
          misc.add(guts)
  for item in breaks:
    result.add(&"- **BREAKING CHANGE** {item}\L")
  for item in fixes:
    result.add(&"- **FIX** {item}\L")
  for item in news:
    result.add(&"- **NEW** {item}\L")
  for item in misc:
    result.add(&"- {item}\L")

proc removeChanges() =
  for thing in os.walkDir(currentSourcePath.parentDir/"changes"):
    if thing.kind == pcFile:
      if thing.path.endsWith(".md"):
        removeFile(thing.path)

task "chlog-echo", "Print the combined CHANGELOG changes to stdout":
  echo combineChanges()

task "chlog", "Update CHANGELOG.md to include the newest changes":
  echo "Updating CHANGELOG.md ..."
  let oldlog = readFile("CHANGELOG.md")
  let newchanges = combineChanges()
  echo newchanges
  writeFile("CHANGELOG.md", newchanges & "\L\L" & oldlog)
  removeChanges()
