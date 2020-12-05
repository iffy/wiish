import strformat
import strutils
import terminal

type
  DoctorStatus* = enum
    NotWorking
    Working
    NotWorkingButOptional

  DoctorResult* = object
    ## A working/not-working dependency check
    name*: string
    status*: DoctorStatus
    error*: string
    fix*: string

proc writeColored(text: string, color: ForegroundColor, fh: File = stdout) =
  ## Write some text in a given color
  setForegroundColor(fh, color)
  fh.write(text)
  fh.resetAttributes()

proc ok*(res: DoctorResult): bool =
  res.status == Working

proc ok*(res: seq[DoctorResult]): bool =
  for x in res:
    if not x.ok:
      return false
  return true

proc display*(res: DoctorResult) =
  case res.status
  of Working:
    writeColored("√ ", fgGreen)
  of NotWorking:
    writeColored("X ", fgRed)
  of NotWorkingButOptional:
    writeColored("o ", fgYellow)
  writeStyled(&"{res.name}\L", {styleBright})
  if res.status in {NotWorking, NotWorkingButOptional}:
    # writeStyled("-".repeat(terminalWidth()-1) & "\L")
    writeColored(&"{res.error}\L", fgYellow)
    stdout.write(&"{res.fix.strip()}\L\L")
    stdout.write("-".repeat(terminalWidth()-1) & "\L")
  # stdout.write("\L")
