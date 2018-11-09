## Logging for Wiish applications
##
import times
import strformat

when defined(ios):
  const appBundleIdentifier {.strdefine.}: string = ""
  
  # Use new iOS logging framework
  {.passL: "-framework Foundation".}
  {.emit: """
  #include <CoreFoundation/CoreFoundation.h>
  #import <os/log.h>
  os_log_t logtype = OS_LOG_DEFAULT;
  """.}
  # Define this proc and call it instead of just emitting the code
  # because {.exportc.} doesn't seem to work outside of a proc
  proc configureLogger(subsystem: cstring) {.exportc.} =
    var the_id {.exportc.} = subsystem
    {.emit: """
    logtype = os_log_create(the_id, "info");
    """.}
  if appBundleIdentifier != "":
    configureLogger(appBundleIdentifier)

  proc systemLog(msg: cstring) =
    var message {.exportc.} = msg
    {.emit: """
    os_log(logtype, "%s", message);
    """ .}
else:
  proc systemLog(msg: string) =
    let ts = now()
    write(stderr, &"{ts} {msg}\L")


proc log*(a: varargs[string]) =
  var message:string
  for s in items(a):
    message.add(" " & s)
  systemLog(message)
