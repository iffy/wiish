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
import ./baseapp

const fmtString = "$levelname [$datetime] "

when wiish_dev:
  # Use a console logger
  proc startLogging*() =
    var console_logger = newConsoleLogger(fmtStr = fmtString)
    addHandler(console_logger)
elif defined(ios):
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
  else:
    {.warning: "Pass -d:appBundleIdentifier=your.app.name to enabled logging".}

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
  
  proc startLogging*() =
    var ios_logger = new IOSLogger
    ios_logger.fmtStr = "$levelname "
    ios_logger.levelThreshold = lvlAll
    addHandler(ios_logger)
elif defined(android):
  const appJavaPackageName {.strdefine.}: string = "org.wiish.app"

  {.emit: """
  #include <android/log.h>
  """.}

  proc systemLog(msg: cstring) =
    var
      message {.exportc.} : cstring = msg
      tag {.exportc.} : cstring = appJavaPackageName
    {.emit: """
    __android_log_write(ANDROID_LOG_INFO, tag, message);
    """.}
    # ANDROID_LOG_INFO, tag, message

  type
    AndroidLogger* = ref object of Logger
  
  method log*(logger: AndroidLogger, level: Level, args: varargs[string, `$`]) =
    ## Logs to the Android system log
    if level >= logger.levelThreshold:
      let ln = substituteLog(logger.fmtStr, level, args)
      try:
        systemLog(ln)
      except IOError:
        systemLog("IOError while attempting to log")
  
  proc startLogging*() =
    var android_logger = new AndroidLogger
    android_logger.fmtStr = "$levelname "
    android_logger.levelThreshold = lvlAll
    addHandler(android_logger)
else:
  # Built, desktop app
  import strformat
  import os
  const appName {.strdefine.}: string = ""
  if appName == "":
    {.warning: "Define -d:appName=name_of_your_app to enable logging".}
  proc startLogging*() =
    var
      logfilename:string
    when defined(macosx):
      logfilename = expandTilde(&"~/Library/Logs/{appName}/log.log")
    if logfilename != "":
      logfilename.parentDir.createDir()
      let rolling_logger = newRollingFileLogger(logfilename, fmtStr = fmtString, bufSize = 0)
      addHandler(rolling_logger)
  
