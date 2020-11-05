import strformat
import terminal

import ./buildutil
import ./build_android
import ./build_ios


proc writeColored(text: string, color: ForegroundColor, fh: File = stdout) =
  ## Write some text in a given color
  setForegroundColor(fh, color)
  fh.write(text)
  fh.resetAttributes()

proc display(res:DoctorResult) =
  case res.status
  of Working:
    writeColored("√ ", fgGreen)
  of NotWorking:
    writeColored("X ", fgRed)
  writeStyled(&"{res.name}", {styleBright})
  if res.status == NotWorking:
    writeColored(&"\L  {res.error}", fgYellow)
    stdout.write(&"\L  {res.fix}")
    stdout.write("\L")
  stdout.write("\L")
  

proc runWiishDoctor*() =
  echo "oo ee oo ah ah"
  for res in build_android.checkDoctor():
    res.display()
  for res in build_ios.checkDoctor():
    res.display()
  