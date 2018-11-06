## Logging for Wiish applications
##
import times
import strformat

when defined(ios):
  {.passL: "-framework Foundation".}
  {.emit: """
  #include <CoreFoundation/CoreFoundation.h>
  extern void NSLog(CFStringRef format, ...);
  """.}
  proc systemLog(msg: cstring) =
    var message {.exportc.} = msg
    {.emit: "NSLog(CFSTR(\"%s\"), message);".}
else:
  proc systemLog(msg: string) =
    let ts = now()
    write(stderr, &"{ts} {msg}\L")


proc log*(a: varargs[string]) =
  var message:string
  for s in items(a):
    message.add(" " & s)
  systemLog(message)
