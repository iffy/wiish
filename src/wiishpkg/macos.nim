import os
import osproc
import ospaths
import strformat

import parsetoml

const default_mac_icon = slurp"./data/default.icns"

proc compileMacos*(directory: string, config:TomlValueRef) =
  ## Compile for macOS

proc doMacRun*(directory:string, config:TomlValueRef) =
  ## Run the mac app
  echo "Doing macOS run..."
  let src_file = (directory/config["main"]["src"].stringVal).normalizedPath
  let args = @["objc", "-r", src_file]
  var p = startProcess(command="nim", args = args, options = {poUsePath, poEchoCmd})
  let result = p.waitForExit()
  quit(result)


proc doMacBuild*(directory:string, config:TomlValueRef) =
  ## Package a mac application
  echo "Doing mac build..."
  let app_name = config["main"]["name"].stringVal
  let src_file = (directory/config["main"]["src"].stringVal).normalizedPath
  let executable_name = src_file.splitFile.name
  echo &"Name: {app_name}"
  let dist_dir = (directory/config["main"]["distDir"].stringVal/"macos").normalizedPath
  echo &"Output dir: {dist_dir}"
  
  let version = config["main"]["version"].stringVal
  let bundle_identifier = config["macos"]["bundle_identifier"].stringVal
  let category_type = config["macos"]["category_type"].stringVal
  
  let unpacked_dir = dist_dir/app_name & ".app"
  let Contents = unpacked_dir/"Contents"
  createDir(Contents)
  createDir(Contents/"Resources")
  createDir(Contents/"MacOS")

  # Contents/PkgInfo
  (Contents/"PkgInfo").writeFile("APPL????")

  # Compile Contents/MacOS/bin
  echo "Compiling with objc..."
  echo getCurrentDir()
  let bin_file = Contents/"MacOS"/executable_name
  let args = @["objc", &"-o:{bin_file}", src_file]
  var p = startProcess(command="nim", args = args, options = {poUsePath, poEchoCmd})
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
  <string>{app_name}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>{version}</string>
  <key>LSMinimumSystemVersionByArchitecture</key>
  <dict>
    <key>x86_64</key>
    <string>10.6</string>
  </dict>
  <key>LSRequiresCarbon</key>
  <true/>
</dict>
</plist>""")