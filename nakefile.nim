import nake
import os
import nimblepkg/cli
import times
import re
import ospaths
import strformat
import strutils
import sequtils
import algorithm
import wiishpkg/building/buildutil

proc basename(x:string):string =
  let split = x.splitFile
  result = split.name & split.ext

proc getLatestVersion():string =
  ## Return the latest released version
  let guts = readFile("wiish.nimble")
  if guts =~ re(".*?version\\s*=\\s*\"(.*?)\"", {reMultiLine, reDotAll}):
    var version = matches[0]
    if version.endsWith("-dev"):
      version = version[0..^5]
    return version
  else:
    raise newException(CatchableError, "Version not detected")

proc updateVersion(newversion:string) =
  ## Write the new version to the nimble package
  let guts = readFile("wiish.nimble")
  let newguts = guts.replacef(re("(.*?version\\s*=\\s*)\"(.*?)\"", {reMultiLine, reDotAll}), "$1\"" & newversion & "\"")
  writeFile("wiish.nimble", newguts)

proc possibleNextVersions(baseversion:string, has_new:bool, has_break:bool):seq[string] =
  ## Suggest three possible next versions
  let
    parts = baseversion.split(".")
    major = &"{parts[0].parseInt+1}.0.0"
    minor = &"{parts[0]}.{parts[1].parseInt+1}.0"
    fix = &"{parts[0]}.{parts[1]}.{parts[2].parseInt+1}"
  if has_break:
    if parts[0] != "0":
      # still in the 0 series
      result.add(@[minor, fix, major])
    else:
      result.add(@[major, minor, fix])
  elif has_new:
    result.add(@[minor, fix, major])
  else:
    result.add(@[fix, minor, major])

template possibleNextVersions(baseversion:string):seq[string] =
  possibleNextVersions(baseversion, has_new = hasChangesOfType("new"), has_break = hasChangesOfType("break"))

template currentDate():string =
  format(now(), "YYYY-MM-dd")

proc hasChangesOfType(kind:string):bool =
  toSeq(walkFiles(&"changes/{kind}-*.md")).len > 0

proc changelogHeader(version:string = ""):string = 
  var version = if version.len == 0: getLatestVersion() else: version
  result.add(&"# v{version} - {currentDate()}\L")

proc combineChanges():string =
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
        echo "rm " & thing.path

proc updateChangelog(version:string) =
  echo "Updating CHANGELOG.md ..."
  let oldlog = readFile("CHANGELOG.md")
  let newchanges = combineChanges()
  let header = changelogHeader(version)
  echo header
  echo newchanges
  writeFile("CHANGELOG.md", header & "\L" & newchanges & "\L\L" & oldlog)
  echo "Wrote to CHANGELOG.md"
  removeChanges()

task "chlog-echo", "Print the combined CHANGELOG changes to stdout":
  let nextVersion = possibleNextVersions(getLatestVersion())[0]
  echo changelogHeader(nextVersion)
  echo combineChanges()

task "release", "Bump the version and update the CHANGELOG":
  var revert:seq[string]
  defer:
    if revert.len > 0:
      echo "To revert, run the following:\L"
      for item in reversed(revert):
        echo &"{item}"
      echo ""

  let lastVersion = getLatestVersion()
  echo "Last version: ", lastVersion
  
  echo "Unreleased changes:\L"
  echo combineChanges()

  let nextVersion = promptList(dontForcePrompt, "Next version?", possibleNextVersions(lastVersion))
  echo "Updating to: ", nextVersion
  let gitTag = "v" & nextVersion

  updateVersion(nextVersion)
  revert.add("git checkout -- wiish.nimble")
  
  updateChangelog(nextVersion)
  revert.add("git checkout -- CHANGELOG.md changes")

  run(@["git", "add", "wiish.nimble", "changes", "CHANGELOG.md"])
  run("git", "status")
  revert.add("git reset HEAD -- wiish.nimble changes CHANGELOG.md")

  run(@["git", "commit", "-m", &"Bump to v{nextVersion}"])
  revert.add("git reset --soft HEAD~1")

  run(@["git", "tag", gitTag])
  revert.add(&"git tag -d {gitTag}")
