import sequtils
import strformat
import strutils
import terminal

import ./building/buildutil

type
  DoctorStatus* = enum
    Working
    NotWorking
    NotWorkingButOptional

  DoctorResult* = object
    ## A working/not-working dependency check
    name*: string
    plugin*: string
    targetOS*: set[TargetOS]
    targetFormat: set[TargetFormat]
    status*: DoctorStatus
    error*: string
    fix*: string

proc writeColored(text: string, color: ForegroundColor, fh: File = stdout) =
  ## Write some text in a given color
  setForegroundColor(fh, color)
  fh.write(text)
  fh.resetAttributes()

proc ok*(res: DoctorResult): bool =
  ## Return true if the item is Working
  res.status in {Working, NotWorkingButOptional}

proc ok*(res: seq[DoctorResult]): bool =
  ## Return true if ALL the items are Working
  for x in res:
    if not x.ok:
      return false
  return true

proc isSelected*(res: DoctorResult, targetOS: set[TargetOS] = {}, targetFormat: set[TargetFormat] = {}, plugins: seq[string] = @[]): bool =
  ## Return true if this DoctorResult passes the filters.
  if targetOS.len > 0 and res.targetOS.len > 0:
    # filter by targetOS
    if (targetOS * res.targetOS).len == 0:
      return false
  if targetFormat.len > 0 and res.targetFormat.len > 0:
    # filter by targetFormat
    if (targetFormat * res.targetFormat).len == 0:
      return false
  if plugins.len > 0 and res.plugin != "":
    # filter by plugins
    if res.plugin notin plugins:
      return false
  return true

proc filter*(res: seq[DoctorResult], targetOS: set[TargetOS] = {}, targetFormat: set[TargetFormat] = {}, plugins: seq[string] = @[]): seq[DoctorResult] =
  ## Return a new seq[DoctorResult] filtered by the given os, target and plugins
  return res.filterIt(it.isSelected(targetOS, targetFormat, plugins))

proc display*(res: DoctorResult, selected = true) =
  var label = res.plugin & "/" & res.name
  if res.targetOS.len > 0:
    label &= " os=" & res.targetOS.mapIt($it).join(",")
  if res.targetFormat.len > 0:
    label &= " target=" & res.targetFormat.mapIt($it).join(",")

  if not selected:
    writeStyled(&"- (SKIPPED) {label}\L", {styleDim})
  else:
    case res.status
    of Working:
      writeColored("√ ", fgGreen)
    of NotWorking:
      writeColored("X ", fgRed)
    of NotWorkingButOptional:
      writeColored("o ", fgYellow)
    writeStyled(&"{label}\L", {styleBright})
    if res.status in {NotWorking, NotWorkingButOptional}:
      writeColored(&"{res.error}\L", fgYellow)
      stdout.write(&"FIX: {res.fix.strip()}\L\L")
      stdout.write("-".repeat(terminalWidth()-1) & "\L")

template dr*(res: var seq[DoctorResult], plugin_s: string, name_s: string, body: untyped): untyped =
  block:
    var dr {.inject.} = DoctorResult(name: name_s, plugin: plugin_s)
    body
    res.add(dr)

