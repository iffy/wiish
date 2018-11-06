## Logging for the wiish command line tool
##
import times
import strformat

proc log*(a: varargs[string]) =
  let ts = now()
  write(stderr, &"{ts} ")
  for s in items(a):
    write(stderr, s)
  write(stderr, "\L")
