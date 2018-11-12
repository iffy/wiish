import os
import osproc
import ospaths
import strformat
import posix
import parsetoml

import ./config
import ./buildutil

proc doLinuxBuild*(directory:string, configPath:string) =
  ## Package a Linux application
  let config = getLinuxConfig(configPath)
  let src_file = directory/config.src
  let executable_name = src_file.splitFile.name
  echo "LINUX IS NOT SUPPORTED YET"
