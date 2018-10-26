import os
import osproc
import ospaths
import strformat
import posix
import parsetoml

import ./config

type
  WindowsConfig = object of Config

proc windowsConfig(config:Config):WindowsConfig =
  result = getConfig[WindowsConfig](config, @["windows", "main"])

proc doWindowsRun*(directory:string, config:Config) =
  ## Run the Windows app
  let config = config.windowsConfig()
  var p:Process
  let src_file = (directory/config.src).normalizedPath
  var args = @[
    "c",
    "-d:glfwStaticLib",
  ]
  for flag in config.nimflags:
    args.add(flag)
  args.add("-r")
  args.add(src_file)
  p = startProcess(command="nim.exe", args = args, options = {poUsePath})
  let result = p.waitForExit()
  quit(result)


proc doWindowsBuild*(directory:string, config:Config) =
  ## Package a Windows application
  let config = config.windowsConfig()
  let src_file = (directory/config.src).normalizedPath
  let executable_name = src_file.splitFile.name
  echo "WINDOWS IS NOT SUPPORTED YET"
