import os
import osproc
import ospaths
import strformat
import posix
import parsetoml

import ./config

type
  MacOSConfig = object of Config
    bundle_identifier*: string
    category_type*: string

const default_mac_icon = slurp"./data/default.icns"

proc macOSConfig(config:Config):MacOSConfig =
  result = getConfig[MacOSConfig](config, @["macos", "main"])
  result.bundle_identifier = config.toml.get(@["macos"], "bundle_identifier", ?"com.wiish.example").stringVal
  result.category_type = config.toml.get(@["macos"], "category_type", ?"public.app-category.example").stringVal

proc doMacRun*(directory:string, config:Config) =
  ## Run the mac app
  let config = config.macOSConfig()
  var p:Process
  let src_file = (directory/config.src).normalizedPath
  var args = @[
    "objc",
    "-d:glfwStaticLib",
  ]
  for flag in config.nimflags:
    args.add(flag)
  args.add("-r")
  args.add(src_file)
  p = startProcess(command="nim", args = args, options = {poUsePath, poParentStreams})
  let result = p.waitForExit()
  quit(result)


proc doMacBuild*(directory:string, config:Config) =
  ## Package a mac application
  let config = config.macOSConfig()
  let src_file = (directory/config.src).normalizedPath
  let executable_name = src_file.splitFile.name
  let dist_dir = (directory/config.dst/"macos").normalizedPath
  
  let version = config.version
  let bundle_identifier = config.bundle_identifier
  let category_type = config.category_type
  
  let unpacked_dir = dist_dir/config.name & ".app"
  let Contents = unpacked_dir/"Contents"
  createDir(Contents)
  createDir(Contents/"Resources")
  createDir(Contents/"MacOS")

  # Contents/PkgInfo
  (Contents/"PkgInfo").writeFile("APPL????")

  # Compile Contents/MacOS/bin
  let bin_file = Contents/"MacOS"/executable_name
  var args = @[
    "objc",
    "-d:glfwStaticLib",
    "-d:release",
  ]
  for flag in config.nimflags:
    args.add(flag)
  args.add(&"-o:{bin_file}")
  args.add(src_file)
  var p = startProcess(command="nim", args = args, options = {poUsePath, poParentStreams})
  let result = p.waitForExit()
  if result != 0:
    echo "Error compiling objc"
    quit(1)

  # copyFile(bin_file, Contents/"MacOS"/executable_name)

  writeFile(Contents/"Resources"/executable_name & ".icns", default_mac_icon)

  # Contents/Info.plist
  # <key>CFBundleIconFile</key>
  # <string>{executable_name}</string>
  (Contents/"Info.plist").writeFile(&"""
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleAllowMixedLocalizations</key>
  <true/>
  <key>CFBundleDevelopmentRegion</key>
  <string>English</string>
  <key>CFBundleExecutable</key>
  <string>{executable_name}</string>
  <key>CFBundleIdentifier</key>
  <string>{bundle_identifier}</string>
  <key>CFBundleIconFile</key>
  <string>{executable_name}.icns</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>{config.name}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>{version}</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>LSMinimumSystemVersionByArchitecture</key>
  <dict>
    <key>x86_64</key>
    <string>10.6</string>
  </dict>
  <key>LSRequiresCarbon</key>
  <true/>
</dict>
</plist>""")