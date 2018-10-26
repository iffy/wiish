import os
import osproc
import ospaths
import strformat
import posix
import parsetoml

import ./config

type
  LinuxConfig = object of Config

proc linuxConfig(config:Config):LinuxConfig =
  result = getConfig[LinuxConfig](config, @["linux", "main"])

proc doLinuxBuild*(directory:string, config:Config) =
  ## Package a Linux application
  let config = config.linuxConfig()
  let src_file = directory/config.src
  let executable_name = src_file.splitFile.name
  echo "LINUX IS NOT SUPPORTED YET"
