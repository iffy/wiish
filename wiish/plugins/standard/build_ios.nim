## Code for building iOS applications.
##
# import parsetoml
# import posix
# import xmlparser
# import xmltree
import json
import logging
import os
import osproc
import regex
import sequtils
import strformat
import strutils

import ./common
import wiish/doctor
import wiish/building/config
import wiish/building/buildutil

const
  CODE_SIGN_IDENTITY_VARNAME = "WIISH_IOS_SIGNING_IDENTITY"
  PROVISIONING_PROFILE_VARNAME = "WIISH_IOS_PROVISIONING_PROFILE_PATH"
  SIMULATOR_APP = "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"

var
  PROV_PROFILE_DIR = expandTilde("~/Library/MobileDevice/Provisioning Profiles")

type
  CodeSignIdentity = object
    hash*: string
    name*: string
    shortid*: string
    fullname*: string

proc listCodesigningIdentities(): seq[CodeSignIdentity] =
  let output = shoutput("security", "find-identity", "-v", "-p", "codesigning")
  for line in output.splitLines():
    match line, rex"""(?x)
\s+\d\)\s+(.*?)\s+"(.*?)\s\((.*?)\)"
    """:
      if matches.len == 0:
        continue
      var identity = CodeSignIdentity()
      identity.hash = matches[0]
      identity.name = matches[1]
      identity.shortid = matches[2]
      identity.fullname = &"{identity.name} ({identity.shortid})"
      result.add(identity)

type
  Device* = tuple
    name: string
    udid: string

proc listAvailableSimulators(): seq[Device] =
  let output = execCmdEx("xcrun simctl list devices 'iphone 11' --json").output
  let data = output.parseJson()
  let devices = data["devices"]
  for k,v in devices.pairs():
    if ".iOS" in k:
      for item in v:
        if item["isAvailable"].getBool(false):
          result.add((item["name"].getStr(), item["udid"].getStr()))


proc listProvisioningProfiles(): seq[string] =
  for kind, thing in walkDir(PROV_PROFILE_DIR):
    result.add(thing)

proc app_dir*(ctx: ref BuildContext): string {.inline.} =
  ## Return the "MyApp.app" path
  ctx.dist_dir / ctx.config.name & ".app"

proc entitlements_file*(ctx: ref BuildContext): string {.inline.} =
  ctx.dist_dir / "Entitlements.plist"

# proc xcode_project_root*(ctx: ref BuildContext): string {.inline.} =
#   ## Path where .xcodeproj file lives
#   ctx.build_dir / "xc"

# proc xcode_project_file*(ctx: ref BuildContext): string {.inline.} =
#   ## Path to .xcodeproj file
#   ctx.build_dir 

proc formatCmd(args:seq[string]):string =
  ## NOT SECURE, but good enough
  var res:seq[string]
  for arg in args:
    if " " in arg:
      res.add(&"'{arg}'")
    else:
      res.add(arg)
  return res.join(" ")

proc signApp(path:string, identity:string, entitlements_path:string = "") =
  ## Sign an iOS/macOS app using an identity

  # Figuring this out was a lot of trial and error.
  # Building an iOS project in Xcode and following along with
  # the build log helped.
  var cmd = @[
    "codesign",
    "--sign", identity,
    "--timestamp=none",
    "--verbose",
  ]
  if entitlements_path != "":
    cmd.add(["--entitlements", entitlements_path])
  cmd.add(path)
  echo "Running cmd:"
  echo cmd.formatCmd()
  sh(cmd)

proc listPossibleSDKVersions(simulator: bool):seq[string] =
  ## List all SDK versions installed on this computer
  let rootdir = if simulator: simulator_sdk_root else: ios_sdk_root
  for kind, thing in walkDir(rootdir):
    let name = thing.extractFilename
    match name, rex".*?(\d+\.\d+)\.sdk":
      if matches.len > 0:
        result.add(matches[0])

proc iosRunStep*(step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Standard iOS Build
  case step
  of Setup:
    ctx.logStartStep()
    ctx.dist_dir = ctx.projectPath / ctx.config.dst / (if ctx.simulator: "ios-sim" else: "ios")
    ctx.build_dir = ctx.projectPath / "build" / "ios"
    ctx.executable_path = ctx.app_dir / "executable"
    ctx.nim_flags.add ctx.config.nimFlags
    ctx.nim_flags.add "-d:appBundleIdentifier=" & ctx.config.bundle_identifier
    var sdk_version = ctx.config.sdk_version
    if sdk_version == "":
      ctx.log &"Choosing SDK version ..."
      let sdk_versions = listPossibleSDKVersions(ctx.simulator)
      ctx.log "Possible SDK versions: " & sdk_versions.join(", ")
      sdk_version = sdk_versions[^1]
      ctx.log &"Chose SDK version: {sdk_version}"
    ctx.ios_sdk_version = sdk_version

    if ctx.xcode_build_destination == "":
      ctx.log &"Choosing xcodebuild -destination ..."
      if ctx.simulator:
        let devices = listAvailableSimulators()
        if devices.len > 0:
          ctx.xcode_build_destination = &"platform=iOS Simulator,name={devices[0].name}"
        else:
          ctx.log "Unable to find any available devices"
          ctx.xcode_build_destination = "generic/platform=iOS Simulator"
      else:
        ctx.xcode_build_destination = "generic/platform=iOS"
      ctx.log &"Chose xcodebuild -destination " & ctx.xcode_build_destination
    
    # ctx.log &"Creating .app structure in {ctx.app_dir} ..."
    # createDir(ctx.app_dir)

    # ctx.log &"Compiling LaunchScreen storyboard ..."
    # # https://gist.github.com/fabiopelosin/4560417
    # sh("ibtool",
    #   "--output-format", "human-readable-text",
    #   "--compile", ctx.app_dir/"LaunchScreen.storyboardc",
    #   stdDatadir/"ios-util"/"LaunchScreen.storyboard",
    #   "--sdk", ctx.ios_sdk_path,
    # )

    # ctx.log &"Creating icons ..."
    # var iconSrcPath:string
    # if ctx.config.icon == "":
    #   iconSrcPath = stdDatadir/"default_square.png"
    # else:
    #   iconSrcPath = ctx.projectPath / ctx.config.icon
    # iconSrcPath.resizePNG(ctx.app_dir/"Icon.png", 180, 180)

    # ctx.log &"Creating Info.plist ..."
    # writeFile(ctx.app_dir / "Info.plist", &"""
    # <?xml version="1.0" encoding="UTF-8" ?>
    # <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    # <plist version="1.0">
    # <dict>
    #   <key>CFBundleName</key>
    #   <string>{ctx.config.name}</string>
    #   <key>CFBundleIdentifier</key>
    #   <string>{ctx.config.bundle_identifier}</string>
    #   <key>CFBundleExecutable</key>
    #   <string>{ctx.executable_path.extractFilename}</string>
    #   <key>CFBundleShortVersionString</key>
    #   <string>{ctx.config.version}</string>
    #   <key>CFBundleVersion</key>
    #   <string>{ctx.config.version}.1</string>
    #   <key>CFBundleIcons</key>
    #   <dict>
    #     <key>CFBundlePrimaryIcon</key>
    #     <dict>
    #       <key>CFBundleIconFiles</key>
    #       <array>
    #         <string>Icon.png</string>
    #       </array>
    #     </dict>
    #   </dict>
    #   <key>UILaunchStoryboardName</key>
    #   <string>LaunchScreen</string>
    #   {ctx.config.info_plist_append}
    # </dict>
    # </plist>
    # """)

    # let
    #   srcResources = ctx.projectPath / ctx.config.resourceDir
    #   dstResources = ctx.app_dir / "static"
    # if srcResources.dirExists:
    #   ctx.log &"Copying resources from {srcResources} to {dstResources} ..."
    #   createDir(dstResources)
    #   copyDir(srcResources, dstResources)
  of PreCompile:
    discard
  of Compile:
    discard
  of PostCompile:
    discard
  of PreBuild:
    ctx.logStartStep()
    # copy in icon
    ctx.log "Creating icons..."
    var iconSrcPath: string
    if ctx.config.icon == "":
      iconSrcPath = stdDatadir / "default_square.png"
    else:
      iconSrcPath = ctx.projectPath / ctx.config.icon
    iconSrcPath.resizePNG(ctx.xcode_project_root / "Icon.png", 180, 180)

    # copy in resources
    ctx.log "Adding static files..."
    let
      srcResources = ctx.projectPath / ctx.config.resourceDir
      dstResources = ctx.xcode_project_root / "static"
    if srcResources.dirExists:
      ctx.log &"Copying resources from {srcResources} to {dstResources} ..."
      createDir(dstResources)
      copyDir(srcResources, dstResources)
    
    # list schemes
    ctx.log "listing schemes..."
    var args = @["xcodebuild",
      "-list",
      "-project", ctx.xcode_project_file,
    ]
    ctx.log args.join(" ")
    try: sh(args)
    except: discard
  of Build:
    ctx.logStartStep()
    var args = @["xcodebuild",
      "-scheme", ctx.xcode_build_scheme,
      "-project", ctx.xcode_project_file,
      "-destination", ctx.xcode_build_destination,
      "clean", "build",
      "CONFIGURATION_BUILD_DIR=" & ctx.dist_dir.absolutePath,
      "PRODUCT_NAME=" & ctx.config.name,
      "PRODUCT_BUNDLE_IDENTIFIER=" & ctx.config.bundle_identifier,
    ]
    ctx.log args.join(" ")
    sh(args)
  of PostBuild:
    discard
  of PrePackage:
    discard
  #   if not ctx.simulator:
  #     ctx.logStartStep
  #     # provisioning profile
  #     var prov_profile = getEnv(PROVISIONING_PROFILE_VARNAME, "")
  #     if prov_profile == "":
  #       let options = listProvisioningProfiles()
  #       if options.len > 0:
  #         debug &"Since {PROVISIONING_PROFILE_VARNAME} was not set, choosing a provisioning profile at random ..."
  #         prov_profile = options[0]
  #       else:
  #         raise newException(CatchableError, "No provisioning profile set.  Run 'wiish doctor' for instructions.")
      
  #     let dst = ctx.app_dir/"embedded.mobileprovision"
  #     ctx.log &"Copying '{prov_profile}' to '{dst}'"
  #     copyFile(prov_profile, dst)

  #     # Extract entitlements from provisioning profile and put them in the signature
  #     let prov_guts = prov_profile.readFile()
  #     let i_prestart = prov_guts.find("<key>Entitlements")
  #     let i_start = prov_guts.find("<dict>", i_prestart)
  #     let i_end = prov_guts.find("</dict>", i_start) + "</dict>".len
  #     let entitlements = prov_guts[i_start .. i_end]
  #     writeFile(ctx.entitlements_file, &"""
  #       <?xml version="1.0" encoding="UTF-8"?>
  #       <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  #       <plist version="1.0">
  #       {entitlements}
  #       </plist>
  #     """)
  #     ctx.log &"Wrote {ctx.entitlements_file}"
  of Package:
    discard
  of PostPackage:
    discard
  of PreSign:
    discard
  of BuildStep.Sign:
    discard
  #   if not ctx.simulator:
  #     ctx.logStartStep
  #     var signing_identity = getEnv(CODE_SIGN_IDENTITY_VARNAME, "")
  #     if signing_identity == "":
  #       let identities = listCodesigningIdentities()
  #       if identities.len > 0:
  #         debug &"Since {CODE_SIGN_IDENTITY_VARNAME} was not set, choosing a signing identity at random ..."
  #         signing_identity = identities[0].fullname

  #     if signing_identity == "":
  #       raise newException(CatchableError, "No signing identity chosen. Run 'wiish doctor' for instructions.")
  #     debug &"Signing app with identity {signing_identity}..."
  #     signApp(ctx.app_dir, signing_identity, ctx.entitlements_file)
  #     ctx.entitlements_file.removeFile()
  of PostSign:
    discard
  of PreNotarize:
    discard
  of Notarize:
    discard
  of PostNotarize:
    discard
  of Run:
    if ctx.simulator:
      if not ctx.app_dir.dirExists():
        raise ValueError.newException("Unable to find app: " & ctx.app_dir)
      var p: Process
      ctx.logStartStep
      # open the simulator
      ctx.log "Opening simulator..."
      p = startProcess(command="open", args = @["-a", SIMULATOR_APP], options = {poUsePath, poParentStreams})
      if p.waitForExit() != 0:
        raise newException(CatchableError, "Error starting simulator")
      
      # wait for the simulator
      ctx.log "Waiting for the simulator to start..."
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
      ctx.log "Installing app..."
      p = startProcess(command="xcrun", args = @[
        "simctl", "install", "booted", ctx.app_dir,
      ], options = {poUsePath, poParentStreams})
      if p.waitForExit() != 0:
        raise newException(CatchableError, "Error installing application")
      
      # Watch the logs
      var args = @["xcrun", "simctl", "spawn", "booted", "log", "stream"]
      if not ctx.verbose:
        args.add(@["--predicate", &"subsystem contains \"{ctx.config.bundle_identifier}\""])
      var logp = startProcess(command=args[0], args = args[1..^1],
        options = {poUsePath, poParentStreams})

      # start the app
      ctx.log &"Starting app {ctx.config.bundle_identifier}..."
      let startmessage = shoutput("xcrun", "simctl", "launch", "booted", ctx.config.bundle_identifier)
      discard startmessage.strip.split(" ")[1]

      # wait for logs to finish
      discard logp.waitForExit()
      # sh(args)
    discard

# proc doiOSBuild*(directory:string, config: WiishConfig):string =
#   ## Build an iOS .app
#   ## Returns the path to the packaged .app
#   let
#     buildDir = directory/config.dst/"ios"
#     appSrc = directory/config.src
#     # sdkName = if simulator: "iphonesimulator" else: "iphoneos"
#     identities = listCodesigningIdentities()
#     appDir = buildDir/config.name & ".app"
#     appInfoPlistPath = appDir/"Info.plist"
#     executablePath = appDir/"executable"
#     srcResources = directory/config.resourceDir
#     dstResources = appDir/"static"
#     simulator = config.ios_simulator
#   var
#     nimFlags, linkerFlags, compilerFlags: seq[string]
#     sdk_version = config.sdk_version
#     sdllibSrc, sdlttflibSrc: string
  
#   if sdk_version == "":
#     debug &"Choosing SDK version ..."
#     let sdk_versions = listPossibleSDKVersions(simulator)
#     debug "Possible SDK versions: " & sdk_versions.join(", ")
#     sdk_version = sdk_versions[^1]
#     debug &"Chose SDK version: {sdk_version}"

#   var sdkPath:string
#   if simulator:
#     sdkPath = simulator_sdk_root / "iPhoneSimulator" & sdk_version & ".sdk"
#   else:
#     sdkPath = ios_sdk_root / "iPhoneOS" & sdk_version & ".sdk"

#   result = appDir
  
#   debug &"Creating .app structure in {appDir} ..."
#   createDir(appDir)

#   debug &"Compiling LaunchScreen storyboard ..."
#   # https://gist.github.com/fabiopelosin/4560417
#   sh("ibtool",
#     "--output-format", "human-readable-text",
#     "--compile", appDir/"LaunchScreen.storyboardc",
#     stdDatadir/"ios-util"/"LaunchScreen.storyboard",
#     "--sdk", sdkPath,
#   )

#   debug &"Creating icons ..."
#   var iconSrcPath:string
#   if config.icon == "":
#     iconSrcPath = stdDatadir/"default_square.png"
#   else:
#     iconSrcPath = directory/config.icon
#   iconSrcPath.resizePNG(appDir/"Icon.png", 180, 180)

#   debug &"Creating Info.plist ..."
#   appInfoPlistPath.writeFile(&"""
#   <?xml version="1.0" encoding="UTF-8" ?>
#   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
#   <plist version="1.0">
#   <dict>
#     <key>CFBundleName</key>
#     <string>{config.name}</string>
#     <key>CFBundleIdentifier</key>
#     <string>{config.bundle_identifier}</string>
#     <key>CFBundleExecutable</key>
#     <string>{executablePath.extractFilename}</string>
#     <key>CFBundleShortVersionString</key>
#     <string>{config.version}</string>
#     <key>CFBundleVersion</key>
#     <string>{config.version}.1</string>
#     <key>CFBundleIcons</key>
#     <dict>
#       <key>CFBundlePrimaryIcon</key>
#       <dict>
#         <key>CFBundleIconFiles</key>
#         <array>
#           <string>Icon.png</string>
#         </array>
#       </dict>
#     </dict>
#     <key>UILaunchStoryboardName</key>
#     <string>LaunchScreen</string>
#   </dict>
#   </plist>
#   """)

#   if srcResources.dirExists:
#     debug &"Copying resources from {srcResources} to {dstResources} ..."
#     createDir(dstResources)
#     copyDir(srcResources, dstResources)

#   if config.windowFormat == SDL:
#     debug "Obtaining SDL2 library ..."
#     sdllibSrc = buildSDLlib(sdk_version, simulator)

#     debug "Obtaining SDL2_ttf library ..."
#     sdlttflibSrc = buildSDLTTFlib(sdk_version, simulator)
  
#   debug "Configuring build ..."
#   template linkAndCompile(flag:untyped) =
#     linkerFlags.add(flag)
#     compilerFlags.add(flag)
  
#   nimFlags.add([
#     "--os:macosx",
#     "-d:ios",
#     "-d:iPhone",
#     &"-d:appBundleIdentifier={config.bundle_identifier}",
#   ])
#   if config.windowFormat == SDL:
#     nimFlags.add([
#       "--dynlibOverride:SDL2",
#       "--dynlibOverride:SDL2_ttf",
#     ])
#   if simulator:
#     nimFlags.add([
#       "--cpu:amd64",
#       "-d:simulator",
#     ])
#   else:
#     nimFlags.add([
#       "--cpu:arm64",
#     ])
#     linkAndCompile(&"-arch arm64")
  
#   if simulator:
#     linkAndCompile(&"-mios-simulator-version-min={sdk_version}")
#   else:
#     linkAndCompile(&"-mios-version-min={sdk_version}")
#   if config.windowFormat == SDL:
#     linkerFlags.add([
#       "-fobjc-link-runtime",
#     ])
#     linkerFlags.add([
#       "-L", sdllibSrc.parentDir,
#       "-L", sdlttflibSrc.parentDir,
#     ])
#   linkAndCompile(["-isysroot", sdkPath])
  
#   if config.windowFormat == SDL:
#     nimFlags.add(["--threads:on"])
#     linkerFlags.add("-lSDL2")
#     linkerFlags.add("-lSDL2_ttf")
#   nimFlags.add([
#     "--warning[LockLevel]:off",
#     "--verbosity:0",
#     "--hint[Pattern]:off",
#     "--parallelBuild:0",
#     "--threads:on",
#     "--tlsEmulation:off",
#     "--out:" & executablePath,
#     "--nimcache:nimcache",
#     ])
#   # nimFlags.add([
#   #   "--noMain",
#   # ])
#   for flag in linkerFlags:
#     nimFlags.add("--passL:" & flag)
#   for flag in compilerFlags:
#     nimFlags.add("--passC:" & flag)
  
#   nimFlags.add(config.nimflags)

#   debug "Doing build ..."
#   var args = @["nim", "objc"]
#   args.add(nimFlags)
#   args.add(appSrc)
#   debug args.join(" ")
#   sh(args)

#   if not simulator:
#     # provisioning profile
#     var prov_profile = getEnv(PROVISIONING_PROFILE_VARNAME, "")
#     if prov_profile == "":
#       let options = listProvisioningProfiles()
#       if options.len > 0:
#         debug &"Since {PROVISIONING_PROFILE_VARNAME} was not set, choosing a provisioning profile at random ..."
#         prov_profile = options[0]
#       else:
#         raise newException(CatchableError, "No provisioning profile set.  Run 'wiish doctor' for instructions.")
    
#     let dst = appDir/"embedded.mobileprovision"
#     debug &"Copying '{prov_profile}' to '{dst}'"
#     copyFile(prov_profile, dst)

#     # Extract entitlements from provisioning profile and put them in the signature
#     let prov_guts = prov_profile.readFile()
#     let i_prestart = prov_guts.find("<key>Entitlements")
#     let i_start = prov_guts.find("<dict>", i_prestart)
#     let i_end = prov_guts.find("</dict>", i_start) + "</dict>".len
#     let entitlements = prov_guts[i_start .. i_end]
#     let entitlements_file = buildDir/"Entitlements.plist"
#     writeFile(entitlements_file, &"""
#       <?xml version="1.0" encoding="UTF-8"?>
#       <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
#       <plist version="1.0">
#       {entitlements}
#       </plist>
#     """)

#     var signing_identity = getEnv(CODE_SIGN_IDENTITY_VARNAME, "")
#     if signing_identity == "":
#       if identities.len > 0:
#         debug &"Since {CODE_SIGN_IDENTITY_VARNAME} was not set, choosing a signing identity at random ..."
#         signing_identity = identities[0].fullname

#     if signing_identity == "":
#       raise newException(CatchableError, "No signing identity chosen. Run 'wiish doctor' for instructions.")
#     debug &"Signing app with identity {signing_identity}..."
#     signApp(appDir, signing_identity, entitlements_file)
#     entitlements_file.removeFile()

# proc doiOSRun*(directory:string = ".", verbose = false) =
#   ## Run the application in an iOS simulator
#   var p: Process
#   let configPath = directory/"wiish.toml"
#   var config = getiOSConfig(parseConfig(configPath))
#   config.ios_simulator = true

#   # compile the app
#   debug "Compiling app..."
#   let apppath = doiOSBuild(directory, config)
  
#   # open the simulator
#   debug "Opening simulator..."
#   p = startProcess(command="open", args = @["-a", "Simulator"], options = {poUsePath, poParentStreams})
#   if p.waitForExit() != 0:
#     raise newException(CatchableError, "Error starting simulator")
  
#   # wait for the simulator
#   debug "Waiting for the simulator to start..."
#   var booted = false
#   for i in 0..20:
#     let output = execProcess(command="xcrun", args = @[
#       "simctl", "list"
#     ], options = {poUsePath})
#     if "Booted" in output:
#       booted = true
#       break
#     sleep(1000)
#   if not booted:
#     raise newException(CatchableError, "Timed out waiting for simulator to start")

#   # install the app
#   debug "Installing app..."
#   p = startProcess(command="xcrun", args = @[
#     "simctl", "install", "booted", apppath,
#   ], options = {poUsePath, poParentStreams})
#   if p.waitForExit() != 0:
#     raise newException(CatchableError, "Error installing application")

#   # start the app
#   debug &"Starting app {config.bundle_identifier}..."
#   let startmessage = shoutput("xcrun", "simctl", "launch", "booted", config.bundle_identifier)
#   let childPid = startmessage.strip.split(" ")[1]

#   # Watch the logs
#   var args = @["xcrun", "simctl", "spawn", "booted", "log", "stream"]
#   if not verbose:
#     args.add(@["--predicate", &"subsystem contains \"{config.bundle_identifier}\""])
#   sh(args)


proc checkDoctor*(): seq[DoctorResult] =
  when defined(macosx):
    result.dr "standard", "xcode":
      dr.targetOS = {Ios,IosSimulator}
      if findExe("xcrun") == "":
        dr.status = NotWorking
        dr.error = "xcode not found"
        dr.fix = "Install Xcode command line tools"
    
    result.dr "standard", "Simulator":
      dr.targetOS = {IosSimulator}
      if not dirExists(SIMULATOR_APP):
        dr.status = NotWorking
        dr.error = "Simulator not found"
        dr.fix = "Install the Xcode Simulator.  It should exist at: " & SIMULATOR_APP
    
    let identities = listCodesigningIdentities().filterIt(it.fullname.startsWith("iPhone"))
    result.dr "standard", "signing-keys":
      dr.targetOS = {Ios}
      if identities.len == 0:
        dr.status = NotWorking
        dr.error = "No valid signing keys installed"
        dr.fix = "Obtain iPhone signing keys from Apple and install them in your keychain."

    result.dr "standard", "chose-signing-key":
      dr.targetOS = {Ios}
      if getEnv(CODE_SIGN_IDENTITY_VARNAME, "") == "":
        dr.status = NotWorking
        dr.error = "No identity chosen for iOS code signing"
        dr.fix = &"""Set {CODE_SIGN_IDENTITY_VARNAME} to one of the options listed by

    security find-identity -v -p codesigning"""
        if identities.len > 0:
          dr.fix.add(&".  For instance: {CODE_SIGN_IDENTITY_VARNAME}='{identities[0].fullname}' might work.")

    result.dr "standard", "provisioning-profile":
      dr.targetOS = {Ios}
      if getEnv(PROVISIONING_PROFILE_VARNAME, "") == "":
        dr.status = NotWorking
        dr.error = "No provisioning profile chosen for iOS code signing"
        dr.fix = &"""Set {PROVISIONING_PROFILE_VARNAME} to the path of a valid provisioning profile.  They can be found with

    ls "{PROV_PROFILE_DIR}"

  though they can also be downloaded from Apple."""
        let possible_profiles = listProvisioningProfiles()
        if possible_profiles.len == 0:
          dr.fix.add("""
  You *might* be able to create such a profile by:
  1. Opening Xcode
  2. Creating a blank iOS project
  3. Enabling 'Automatically manage signing'
  4. Building the project once.

  TODO: come up with less goofy instructions.""")
        else:
          dr.fix.add(&""" For instance, this might work:
  
    {PROVISIONING_PROFILE_VARNAME}='{possible_profiles[0]}'""")
  else:
    result.dr "standard", "os":
      dr.targetOS = {Ios,IosSimulator}
      dr.status = NotWorkingButOptional
      dr.error = "iOS can only be built on the macOS operating system"
      dr.fix = "Give money to Apple to fix this"
  
    