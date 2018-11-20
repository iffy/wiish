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
import logging

import ./config
import ./buildutil

const
  simulator_sdk_root = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/"

type
  CodeSignIdentity = object
    hash*: string
    name*: string
    shortid*: string
    fullname*: string

proc listCodesigningIdentities(): seq[CodeSignIdentity] =
  let output = runoutput("security", "find-identity", "-v", "-p", "codesigning")
  for line in output.splitLines():
    if line =~ re("\\s+\\d\\)\\s+(.*?)\\s+\"(.*?)\\s\\((.*?)\\)"):
      var identity = CodeSignIdentity()
      identity.hash = matches[0]
      identity.name = matches[1]
      identity.shortid = matches[2]
      identity.fullname = &"{identity.name} ({identity.shortid})"
      result.add(identity)

proc buildSDLlib(sdk_version:string, simulator:bool = true):string =
  ## Returns the path to libSDL2.a, creating it if necessary
  let
    platform = if simulator: "iphonesimulator" else: "iphoneos"
    xcodeProjPath = DATADIR()/"SDL/Xcode-iOS/SDL"
  result = (xcodeProjPath/"build/Release-" & platform)/"libSDL2.a"
  if not fileExists(result):
    debug &"Building {result.basename}..."
    var args = @[
      "xcodebuild",
      "-project", xcodeProjPath/"SDL.xcodeproj",
      "-configuration", "Release",
      "-sdk", platform & sdk_version,
      "SYMROOT=build",
    ]
    if simulator:
      args.add("ARCHS=i386 x86_64")
    else:
      args.add("ARCHS=arm64 armv7")
    run(args)
  else:
    debug &"Using existing {result.basename}"
  
  if not fileExists(result):
    raise newException(CatchableError, "Failed to build libSDL2.a")

proc buildSDLTTFlib(sdk_version:string, simulator:bool = true):string =
  ## Returns the path to libSDL2
  let
    platform = if simulator: "iphonesimulator" else: "iphoneos"
    xcodeProjPath = DATADIR()/"SDL_TTF/Xcode-iOS"
  result = (xcodeProjPath/"build/Release-" & platform)/"libSDL2_ttf.a"
  if not fileExists(result):
    debug &"Building {result.basename}..."
    var args = @[
      "xcodebuild",
      "-project", xcodeProjPath/"SDL_ttf.xcodeproj",
      "-configuration", "Release",
      "-sdk", platform & sdk_version,
      "SYMROOT=build",
    ]
    if simulator:
      args.add("ARCHS=i386 x86_64")
    else:
      args.add("ARCHS=arm64 armv7")
    run(args)
  else:
    debug &"Using existing {result.basename}"
  
  if not fileExists(result):
    raise newException(CatchableError, "Failed to build libSDL2.a")

proc listPossibleSDKVersions(simulator: bool):seq[string] =
  ## List all SDK versions installed on this computer
  for kind, thing in walkDir(simulator_sdk_root):
    let name = thing.basename
    if name =~ re".*?(\d+\.\d+)\.sdk":
      result.add(matches[0])

proc doiOSBuild*(directory:string, configPath:string, release:bool = true):string =
  ## Build an iOS .app
  ## Returns the path to the packaged .app
  let
    config = getiOSConfig(configPath)
    buildDir = directory/config.dst/"ios"
    appSrc = directory/config.src
    simulator = true
    sdkName = if simulator: "iphonesimulator" else: "iphoneos"
    identities = listCodesigningIdentities()
    appDir = buildDir/config.name & ".app"
    appInfoPlistPath = appDir/"Info.plist"
    executablePath = appDir/"executable"
    srcResources = directory/config.resourceDir
    dstResources = appDir/"static"
  var
    nimFlags, linkerFlags, compilerFlags: seq[string]
    sdk_version = config.sdk_version
    sdllibSrc, sdlttflibSrc: string
  
  if sdk_version == "":
    debug &"Choosing sdk version ..."
    sdk_version = listPossibleSDKVersions(simulator)[^1]
    debug &"Chose SDK version: {sdk_version}"

  var sdkPath:string
  if simulator:
    sdkPath = simulator_sdk_root / "iPhoneSimulator" & sdk_version & ".sdk"
  else:
    raise newException(CatchableError, "Non-simulator not yet supported")

  result = appDir
  
  debug &"Creating .app structure in {appDir} ..."
  createDir(appDir)

  debug &"Compiling LaunchScreen storyboard ..."
  # https://gist.github.com/fabiopelosin/4560417
  run("ibtool",
    "--output-format", "human-readable-text",
    "--compile", appDir/"LaunchScreen.storyboardc",
    DATADIR()/"ios-util"/"LaunchScreen.storyboard",
    "--sdk", sdkPath,
  )

  debug &"Creating icons ..."
  var iconSrcPath:string
  if config.icon == "":
    iconSrcPath = DATADIR()/"default_square.png"
  else:
    iconSrcPath = directory/config.icon
  iconSrcPath.resizePNG(appDir/"Icon.png", 180, 180)

  debug &"Creating Info.plist ..."
  appInfoPlistPath.writeFile(&"""
  <?xml version="1.0" encoding="UTF-8" ?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>CFBundleName</key>
    <string>{config.name}</string>
    <key>CFBundleIdentifier</key>
    <string>{config.bundle_identifier}</string>
    <key>CFBundleExecutable</key>
    <string>{executablePath.basename}</string>
    <key>CFBundleShortVersionString</key>
    <string>{config.version}</string>
    <key>CFBundleVersion</key>
    <string>{config.version}.1</string>
    <key>CFBundleIcons</key>
    <dict>
      <key>CFBundlePrimaryIcon</key>
      <dict>
        <key>CFBundleIconFiles</key>
        <array>
          <string>Icon.png</string>
        </array>
      </dict>
    </dict>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
  </dict>
  </plist>
  """)

  if srcResources.dirExists:
    debug &"Copying resources from {srcResources} to {dstResources} ..."
    createDir(dstResources)
    copyDir(srcResources, dstResources)

  # debug "Choosing signing identity ..."
  # let signing_identity = identities[0].fullname

  if config.windowFormat == SDL:
    debug "Obtaining SDL2 library ..."
    sdllibSrc = buildSDLlib(sdk_version, simulator)

    debug "Obtaining SDL2_ttf library ..."
    sdlttflibSrc = buildSDLTTFlib(sdk_version, simulator)
  
  debug "Configuring build ..."
  template linkAndCompile(flag:untyped) =
    linkerFlags.add(flag)
    compilerFlags.add(flag)
  
  nimFlags.add([
    "--os:macosx",
    "-d:ios",
    "-d:iPhone",
    &"-d:appBundleIdentifier={config.bundle_identifier}",
  ])
  if config.windowFormat == SDL:
    nimFlags.add([
      "--dynlibOverride:SDL2",
      "--dynlibOverride:SDL2_ttf",
    ])
  if simulator:
    nimFlags.add([
      "--cpu:amd64",
      "-d:simulator",
    ])
  else:
    raise newException(CatchableError, "Non-simulator not yet supported")
  
  linkAndCompile(&"-mios-simulator-version-min={sdk_version}")
  if config.windowFormat == SDL:
    linkerFlags.add([
      "-fobjc-link-runtime",
    ])
    linkerFlags.add([
      "-L", sdllibSrc.parentDir,
      "-L", sdlttflibSrc.parentDir,
    ])
  linkAndCompile(["-isysroot", sdkPath])
  
  if config.windowFormat == SDL:
    nimFlags.add(["--threads:on"])
    linkerFlags.add("-lSDL2")
    linkerFlags.add("-lSDL2_ttf")
  nimFlags.add([
    "--warning[LockLevel]:off",
    "--verbosity:0",
    "--hint[Pattern]:off",
    "--parallelBuild:0",
    "--out:" & executablePath,
    "--nimcache:nimcache",
    ])
  nimFlags.add([
    "--noMain",
  ])
  for flag in linkerFlags:
    nimFlags.add("--passL:" & flag)
  for flag in compilerFlags:
    nimFlags.add("--passC:" & flag)
  
  debug "Doing build ..."
  var args = @["nim", "objc"]
  args.add(nimFlags)
  args.add(appSrc)
  # debug args.join(" ")
  run(args)

proc doiOSRun*(directory:string = ".") =
  ## Run the application in an iOS simulator
  var
    args: seq[string]
    p: Process
  let
    configPath = directory/"wiish.toml"
    config = getiOSConfig(configPath)

  # compile the app
  debug "Compiling app..."
  let apppath = doiOSBuild(directory, configPath, release = false)
  
  # open the simulator
  debug "Opening simulator..."
  p = startProcess(command="open", args = @["-a", "Simulator"], options = {poUsePath, poParentStreams})
  if p.waitForExit() != 0:
    raise newException(CatchableError, "Error starting simulator")
  
  # wait for the simulator
  debug "Waiting for the simulator to start..."
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
  debug "Installing app..."
  p = startProcess(command="xcrun", args = @[
    "simctl", "install", "booted", apppath,
  ], options = {poUsePath, poParentStreams})
  if p.waitForExit() != 0:
    raise newException(CatchableError, "Error installing application")

  # start the app
  debug &"Starting app {config.bundle_identifier}..."
  let startmessage = runoutput("xcrun", "simctl", "launch", "booted", config.bundle_identifier)
  let childPid = startmessage.strip.split(" ")[1]

  # Watch the logs
  run("xcrun", "simctl", "spawn", "booted", "log", "stream",
    "--predicate", &"subsystem contains \"{config.bundle_identifier}\"")
