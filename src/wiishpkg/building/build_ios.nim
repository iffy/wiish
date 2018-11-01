import os
import osproc
import ospaths
import strformat
import strutils
import parsetoml
import posix

import ./config
import ./logging

type
  iOSConfig = object of Config
    bundle_identifier*: string
    category_type*: string

proc getiOSConfig(config:Config):iOSConfig =
  result = getMobileConfig[iOSConfig](config, @["ios", "mobile"])
  result.bundle_identifier = config.toml.get(@["ios"], "bundle_identifier", ?"com.wiish.example").stringVal
  result.category_type = config.toml.get(@["ios"], "category_type", ?"public.app-category.example").stringVal

proc createOrUpdateXCodeProject(directory:string, config:Config) =
  # For right now, this proc obliterates what's there
  # In the future it might just update as needed
  let projdir = directory/config.dst/"ios"/"proj"
  createDir(projdir)


proc doiOSBuild*(directory:string, config:Config, release:bool = true):string =
  ## Package a iOS application
  let config = config.getiOSConfig()
  let src_file = directory/config.src
  let executable_name = src_file.splitFile.name
  let dist_dir = directory/config.dst/"ios"
  
  let version = config.version

  createOrUpdateXCodeProject(directory, config)
  
  # let Contents = dist_dir/config.name & ".app"
  # result = Contents
  # createDir(Contents)

  # # ./PkgInfo
  # (Contents/"PkgInfo").writeFile("APPL????")

  # # ./binary
  # let bin_file = Contents/executable_name
  # var args = @[
  #   "objc",
  #   "-d:glfwStaticLib",
  # ]
  # if release:
  #   args.add("-d:release")
  # for flag in config.nimflags:
  #   args.add(flag)
  # args.add(&"-o:{bin_file}")
  # args.add(src_file)
  # var p = startProcess(command="nim", args = args, options = {poUsePath, poParentStreams})
  # if p.waitForExit() != 0:
  #   echo "Error compiling objc"
  #   quit(1)

  # # writeFile(Contents/executable_name & ".icns", default_mac_icon)

  # # Contents/Info.plist
  # # <key>CFBundleIconFile</key>
  # # <string>{executable_name}</string>
  # (Contents/"Info.plist").writeFile(&"""
  # <?xml version="1.0" encoding="UTF-8"?>
  # <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  # <plist version="1.0">
  # <dict>
  #   <key>CFBundleName</key>
  #   <string>{config.name}</string>
  #   <key>DTSDKName</key>
  #   <string>iphonesimulator11.2</string>
  #   <key>DTXcode</key>
  #   <string>0920</string>
  #   <key>UILaunchStoryboardName</key>
  #   <string>LaunchScreen</string>
  #   <key>DTSDKBuild</key>
  #   <string>15C107</string>
  #   <key>CFBundleDevelopmentRegion</key>
  #   <string>en</string>
  #   <key>CFBundleVersion</key>
  #   <string>1</string>
  #   <key>BuildMachineOSBuild</key>
  #   <string>16G1510</string>
  #   <key>DTPlatformName</key>
  #   <string>iphonesimulator</string>
  #   <key>CFBundlePackageType</key>
  #   <string>APPL</string>
  #   <key>CFBundleShortVersionString</key>
  #   <string>{config.version}</string>
  #   <key>CFBundleSupportedPlatforms</key>
  #   <array>
  #     <string>iPhoneSimulator</string>
  #   </array>
  #   <key>UIMainStoryboardFile</key>
  #   <string>Main</string>
  #   <key>UIStatusBarHidden</key>
  #   <true/>
  #   <key>CFBundleInfoDictionaryVersion</key>
  #   <string>6.0</string>
  #   <key>CFBundleExecutable</key>
  #   <string>{executable_name}</string>
  #   <key>DTCompiler</key>
  #   <string>com.apple.compilers.llvm.clang.1_0</string>
  #   <key>UIRequiredDeviceCapabilities</key>
  #   <array>
  #     <string>armv7</string>
  #   </array>
  #   <key>MinimumOSVersion</key>
  #   <string>11.2</string>
  #   <key>CFBundleIdentifier</key>
  #   <string>{config.bundle_identifier}</string>
  #   <key>UIDeviceFamily</key>
  #   <array>
  #     <integer>1</integer>
  #     <integer>2</integer>
  #   </array>
  #   <key>DTPlatformVersion</key>
  #   <string>11.2</string>
  #   <key>DTXcodeBuild</key>
  #   <string>9C40b</string>
  #   <key>LSRequiresIPhoneOS</key>
  #   <true/>
  #   <key>UISupportedInterfaceOrientations</key>
  #   <array>
  #     <string>UIInterfaceOrientationPortrait</string>
  #     <string>UIInterfaceOrientationLandscapeLeft</string>
  #     <string>UIInterfaceOrientationLandscapeRight</string>
  #   </array>
  #   <key>UISupportedInterfaceOrientations~ipad</key>
  #   <array>
  #     <string>UIInterfaceOrientationPortrait</string>
  #     <string>UIInterfaceOrientationPortraitUpsideDown</string>
  #     <string>UIInterfaceOrientationLandscapeLeft</string>
  #     <string>UIInterfaceOrientationLandscapeRight</string>
  #   </array>
  #   <key>DTPlatformBuild</key>
  #   <string></string>
  # </dict>
  # </plist>
  # """)

proc doiOSRun*(directory:string = ".") =
  ## Run the application in an iOS simulator
  var
    args: seq[string]
    p: Process
  let config = getiOSConfig(getMobileConfig(directory/"wiish.toml"))

  # compile the app
  log("Compiling app...")
  let apppath = doiOSBuild(directory, config, release = false)
  
  # open the simulator
  log("Opening simulator...")
  p = startProcess(command="open", args = @["-a", "Simulator"], options = {poUsePath, poParentStreams})
  if p.waitForExit() != 0:
    raise newException(CatchableError, "Error starting simulator")
  
  # wait for the simulator
  log("Waiting for the simulator to start...")
  var booted = false
  for i in 0..20:
    let output = execProcess(command="xcrun", args = @[
      "simctl", "list"
    ], options = {poUsePath})
    if "Booted" in output:
      booted = true
      break
    sleep(1000)
  if not booted:
    raise newException(CatchableError, "Timed out waiting for simulator to start")

  # install the app
  log("Installing app...")
  p = startProcess(command="xcrun", args = @[
    "simctl", "install", "booted", apppath,
  ], options = {poUsePath, poParentStreams})
  if p.waitForExit() != 0:
    raise newException(CatchableError, "Error installing application")

  # start the app
  log("Starting app...")
  p = startProcess(command="xcrun", args = @[
    "simctl", "launch", "booted", config.bundle_identifier,
  ], options = {poUsePath, poParentStreams})
  if p.waitForExit() != 0:
    raise newException(CatchableError, "Error launching application")

