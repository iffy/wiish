## Logging for the wiish command line tool
##
import times
import strformat

proc log*(a: varargs[string]) =
  let ts = now()
  stderr.write(&"{ts} ")
  for s in items(a):
    stderr.write(s)
  stderr.write("\L")
  stderr.flushFile()
