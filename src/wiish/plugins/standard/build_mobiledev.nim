import logging
import os
import strutils
import ./config
import ./buildutil

proc doMobileDevRun*(directory: string = ".", verbose = false) =
  ## Run the application in a simulated environment
  let configPath = directory/"wiish.toml"
  var config = getMobileDevConfig(configPath)

  echo $config

  debug "Compiling app..."
  let
    buildDir = directory/config.dst/"dev"
    appSrc = directory/config.src
  var nimFlags: seq[string]

  case config.windowFormat:
  of Webview:
    nimFlags.add([
      "-d:wiish_webview",
    ])
  else:
    raise newException(ValueError, "Unsupported window format")
  
  nimFlags.add([
    "-d:wiish_mobiledev",
    "-r",
  ])

  var args = @["nim", "c"]
  args.add(nimFlags)
  args.add(appSrc)
  let old_dir = getCurrentDir().absolutePath()
  try:
    debug "cd " & directory
    setCurrentDir(directory)
    debug args.join(" ")
    run(args)
  finally:
    setCurrentDir(old_dir)