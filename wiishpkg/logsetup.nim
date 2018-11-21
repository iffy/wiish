## Logging for Wiish applications.  By importing this module,
## the Nim stdlib ``logging`` module will be configured to log
## somewhere helpful.
##
## When running applications in dev mode (i.e. ``wiish run ...``)
## logs will be printed to the console.
##
## For built applications, logs will be written to the following files:
##
##  - **macOS**: ``~/Library/Logs/{appName}/log.log``
##  - **Linux**: not yet implemented
##  - **Windows**: not yet implemented
##  - **iOS**: not yet implemented
##  - **Android**: not yet implemented
##
import logging
import strformat
import os

const fmtString = "$levelname [$datetime] "
const appName {.strdefine.}: string = ""

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
  
  type
    IOSLogger* = ref object of Logger
  
  method log*(logger: IOSLogger, level: Level, args: varargs[string, `$`]) =
    ## Logs to the iOS system log
    if level >= logger.levelThreshold:
      let ln = substituteLog(logger.fmtStr, level, args)
      try:
        systemLog(ln)
      except IOError:
        discard
  
  var ios_logger = new IOSLogger
  ios_logger.fmtStr = "$levelname "
  ios_logger.levelThreshold = lvlAll
  addHandler(ios_logger)
elif defined(wiishDev):
  # Use a console logger
  var console_logger = newConsoleLogger(fmtStr = fmtString)
  addHandler(console_logger)
else:
  # Built, desktop app
  if appName != "":
    var
      logfilename:string
    when defined(macosx):
      logfilename = expandTilde(&"~/Library/Logs/{appName}/log.log")
    if logfilename != "":
      logfilename.parentDir.createDir()
      let rolling_logger = newRollingFileLogger(logfilename, fmtStr = fmtString, bufSize = 0)
      addHandler(rolling_logger)
