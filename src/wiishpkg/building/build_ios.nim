## Code for building iOS applications.
##
import os
import osproc
import ospaths
import strformat
import strutils
import parsetoml
import posix
import re

import ./config
import ./logging

type
  iOSConfig = object of Config
    bundle_identifier*: string
    category_type*: string
    codesign_identity*: string

const
  datadir = currentSourcePath.parentDir.joinPath("data")

proc getiOSConfig(config:Config):iOSConfig =
  result = getMobileConfig[iOSConfig](config, @["ios", "mobile"])
  result.bundle_identifier = config.toml.get(@["ios"], "bundle_identifier", ?"com.wiish.example").stringVal
  result.category_type = config.toml.get(@["ios"], "category_type", ?"public.app-category.example").stringVal
  result.codesign_identity = config.toml.get(@["ios", "mobile"], "codesign_identity", ?"unknown").stringVal

proc createOrUpdateXCodeProject(directory:string, config:Config):string =
  # For right now, this proc obliterates what's there, but in the future it might just update files as needed.
  let
    projdir = directory/config.dst/"ios"/"xcodeproj"
    src = datadir/"ios_xcodeproj"
  echo &"copying {src} to {projdir}"
  copyDir(src, projdir)
  result = projdir

#   const samples = toSeq(walkDirRec(basepath)).map(proc(x:string):PackedFile =
#   return (x[basepath.len+1..^1], slurp(x))
# )


type
  CodeSignIdentity = object
    hash*: string
    name*: string
    shortid*: string
    fullname*: string
proc listCodesigningIdentities(): seq[CodeSignIdentity] =
  let output = execProcess(command = "security", args = @[
    "find-identity", "-v", "-p", "codesigning",
  ], options = {poUsePath})
  for line in output.splitLines():
    if line =~ re("\\s+\\d\\)\\s+(.*?)\\s+\"(.*?)\\s\\((.*?)\\)"):
      var identity = CodeSignIdentity()
      identity.hash = matches[0]
      identity.name = matches[1]
      identity.shortid = matches[2]
      identity.fullname = &"{identity.name} ({identity.shortid})"
      result.add(identity)


proc doiOSBuild*(directory:string, config:Config, release:bool = true):string =
  ## Package a iOS application
  var
    p: Process
  let config = config.getiOSConfig()
  let src_file = directory/config.src
  let executable_name = src_file.splitFile.name
  let dist_dir = directory/config.dst/"ios"
  
  let version = config.version

  let projdir = createOrUpdateXCodeProject(directory, config)
  
  # find an identity to sign with
  var identities = listCodesigningIdentities()

  # build it
  let configuration = "Debug"
  let sdk_name = "iphonesimulator"
  p = startProcess(command = "xcrun", args = @[
    "xcodebuild",
    "build",
    "-configuration", configuration,
    "-arch", "x86_64",
    "-sdk", &"{sdk_name}11.2",
    "-project", projdir/"nim_ios.xcodeproj",
    &"CODE_SIGN_IDENTITY=\"{identities[0].fullname}\"",
    "ARCH=x86_64",
    "ARCHS_STANDARD_32_64_BIT=x86_64",
    "ARCHS_STANDARD=x86_64",
    "ARCHS=x86_64",
    "CURRENT_ARCH=x86_64",
    "ONLY_ACTIVE_ARCH=NO",
    "VALID_ARCHS=x86_64 armv7s x86_64",
    "PLATFORM_PREFERRED_ARCH=x86_64",
    &"PRODUCT_BUNDLE_IDENTIFIER={config.bundle_identifier}",
    &"PRODUCT_NAME={config.name}",
    &"TARGET_NAME={config.name}",
  ], options = {poUsePath, poParentStreams})
  if p.waitForExit() != 0:
    log("Error building")
    quit(1)

  result = projdir/"build"/(&"{configuration}-{sdk_name}")/(&"{config.name}.app")
  echo "app name: ", result.repr

  # xcodebuild clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -project nim_ios.xcodeproj/
  
  
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

  # XXX figure out how to know when it's installed
  # log("Sleeping 5 seconds to hopefully wait for the app to get installed...")
  # sleep(5000)

  # start the app
  log(&"Starting app {config.bundle_identifier}...")
  p = startProcess(command="xcrun", args = @[
    "simctl", "launch", "booted", config.bundle_identifier,
  ], options = {poUsePath, poParentStreams})
  if p.waitForExit() != 0:
    raise newException(CatchableError, "Error launching application")

  # Watch logs, see
  # xcrun simctl spawn booted log help stream
  # xcrun simctl spawn booted log stream --predicate 'processId > 100'
