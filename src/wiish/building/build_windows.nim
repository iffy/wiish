import os
import osproc
import ospaths
import strformat
import parsetoml

import ./config

proc doWindowsBuild*(directory: string, config: WiishConfig) =
  ## Package a Windows application
  # let src_file = directory/config.src
  # let executable_name = src_file.splitFile.name
  echo "WINDOWS IS NOT SUPPORTED YET"
