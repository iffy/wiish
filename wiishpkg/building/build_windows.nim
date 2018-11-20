import os
import osproc
import ospaths
import strformat
import parsetoml

import ./config

proc doWindowsBuild*(directory:string, configPath:string) =
  ## Package a Windows application
  let config = getWindowsConfig(configPath)
  let src_file = directory/config.src
  let executable_name = src_file.splitFile.name
  echo "WINDOWS IS NOT SUPPORTED YET"
