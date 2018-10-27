import os
import osproc
import ospaths
import strformat
import parsetoml

import ./config

type
  WindowsConfig = object of Config

proc windowsConfig(config:Config):WindowsConfig =
  result = getDesktopConfig[WindowsConfig](config, @["windows", "desktop"])

proc doWindowsBuild*(directory:string, config:Config) =
  ## Package a Windows application
  let config = config.windowsConfig()
  let src_file = directory/config.src
  let executable_name = src_file.splitFile.name
  echo "WINDOWS IS NOT SUPPORTED YET"
