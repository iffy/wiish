## Code for building iOS applications.
##
import os
import osproc
import strformat
import strutils
# import parsetoml
# import posix
import re
import logging
import sequtils
# import xmltree
# import xmlparser

import wiish/building/config
import wiish/building/buildutil

const
  simulator_sdk_root = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/"
  ios_sdk_root = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/"
  CODE_SIGN_IDENTITY_VARNAME = "WIISH_IOS_SIGNING_IDENTITY"
  PROVISIONING_PROFILE_VARNAME = "WIISH_IOS_PROVISIONING_PROFILE_PATH"

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
    if line =~ re("\\s+\\d\\)\\s+(.*?)\\s+\"(.*?)\\s\\((.*?)\\)"):
      var identity = CodeSignIdentity()
      identity.hash = matches[0]
      identity.name = matches[1]
      identity.shortid = matches[2]
      identity.fullname = &"{identity.name} ({identity.shortid})"
      result.add(identity)

proc listProvisioningProfiles(): seq[string] =
  for kind, thing in walkDir(PROV_PROFILE_DIR):
    result.add(thing)

proc simulator*(ctx: ref BuildContext): bool {.inline.} =
  ## Return whether this build is for the iOS simulator or not.
  ctx.targetOS == IosSimulator

proc ios_sdk_path*(ctx: ref BuildContext): string =
  ## Given an sdk version, return the path to the SDK
  if ctx.simulator:
    return simulator_sdk_root / "iPhoneSimulator" & ctx.ios_sdk_version & ".sdk"
  else:
    return ios_sdk_root / "iPhoneOS" & ctx.ios_sdk_version & ".sdk"

proc app_dir*(ctx: ref BuildContext): string {.inline.} =
  ## Return the "MyApp.app" path
  ctx.build_dir / ctx.config.name & ".app"

proc entitlements_file*(ctx: ref BuildContext): string {.inline.} =
  ctx.build_dir / "Entitlements.plist"

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

# proc buildSDLlib(sdk_version:string, simulator:bool = true):string =
#   ## Returns the path to libSDL2.a, creating it if necessary
#   let
#     platform = if simulator: "iphonesimulator" else: "iphoneos"
#     xcodeProjPath = DATADIR()/"SDL/Xcode-iOS/SDL"
#   result = (xcodeProjPath/"build/Release-" & platform)/"libSDL2.a"
#   if not fileExists(result):
#     debug &"Building {result.extractFilename}..."
#     var args = @[
#       "xcodebuild",
#       "-project", xcodeProjPath/"SDL.xcodeproj",
#       "-configuration", "Release",
#       "-sdk", platform & sdk_version,
#       "SYMROOT=build",
#     ]
#     if simulator:
#       args.add("ARCHS=i386 x86_64")
#     else:
#       args.add("ARCHS=arm64 armv7")
#     sh(args)
#   else:
#     debug &"Using existing {result.extractFilename}"
  
#   if not fileExists(result):
#     raise newException(CatchableError, "Failed to build libSDL2.a")

# proc buildSDLTTFlib(sdk_version:string, simulator:bool = true):string =
#   ## Returns the path to libSDL2
#   let
#     platform = if simulator: "iphonesimulator" else: "iphoneos"
#     xcodeProjPath = DATADIR()/"SDL_TTF/Xcode-iOS"
#   result = (xcodeProjPath/"build/Release-" & platform)/"libSDL2_ttf.a"
#   if not fileExists(result):
#     debug &"Building {result.extractFilename}..."
#     var args = @[
#       "xcodebuild",
#       "-project", xcodeProjPath/"SDL_ttf.xcodeproj",
#       "-configuration", "Release",
#       "-sdk", platform & sdk_version,
#       "SYMROOT=build",
#     ]
#     if simulator:
#       args.add("ARCHS=i386 x86_64")
#     else:
#       args.add("ARCHS=arm64 armv7")
#     sh(args)
#   else:
#     debug &"Using existing {result.extractFilename}"
  
#   if not fileExists(result):
#     raise newException(CatchableError, "Failed to build libSDL2.a")

proc listPossibleSDKVersions(simulator: bool):seq[string] =
  ## List all SDK versions installed on this computer
  let rootdir = if simulator: simulator_sdk_root else: ios_sdk_root
  for kind, thing in walkDir(rootdir):
    let name = thing.extractFilename
    if name =~ re".*?(\d+\.\d+)\.sdk":
      result.add(matches[0])


proc iosRunStep*(step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Standard iOS Build
  case step
  of Setup:
    ctx.logStartStep()
    ctx.build_dir = ctx.projectPath / ctx.config.dst / "ios"
    ctx.executable_path = ctx.app_dir / "executable"
    var sdk_version = ctx.config.sdk_version
    if sdk_version == "":
      debug &"Choosing SDK version ..."
      let sdk_versions = listPossibleSDKVersions(ctx.simulator)
      debug "Possible SDK versions: " & sdk_versions.join(", ")
      sdk_version = sdk_versions[^1]
      debug &"Chose SDK version: {sdk_version}"
    ctx.ios_sdk_version = sdk_version
    
    ctx.log &"Creating .app structure in {ctx.app_dir} ..."
    createDir(ctx.app_dir)

    ctx.log &"Compiling LaunchScreen storyboard ..."
    # https://gist.github.com/fabiopelosin/4560417
    sh("ibtool",
      "--output-format", "human-readable-text",
      "--compile", ctx.app_dir/"LaunchScreen.storyboardc",
      DATADIR()/"ios-util"/"LaunchScreen.storyboard",
      "--sdk", ctx.ios_sdk_path,
    )

    ctx.log &"Creating icons ..."
    var iconSrcPath:string
    if ctx.config.icon == "":
      iconSrcPath = DATADIR()/"default_square.png"
    else:
      iconSrcPath = ctx.projectPath / ctx.config.icon
    iconSrcPath.resizePNG(ctx.app_dir/"Icon.png", 180, 180)

    ctx.log &"Creating Info.plist ..."
    writeFile(ctx.app_dir / "Info.plist", &"""
    <?xml version="1.0" encoding="UTF-8" ?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleName</key>
      <string>{ctx.config.name}</string>
      <key>CFBundleIdentifier</key>
      <string>{ctx.config.bundle_identifier}</string>
      <key>CFBundleExecutable</key>
      <string>{ctx.executable_path.extractFilename}</string>
      <key>CFBundleShortVersionString</key>
      <string>{ctx.config.version}</string>
      <key>CFBundleVersion</key>
      <string>{ctx.config.version}.1</string>
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

    let
      srcResources = ctx.projectPath / ctx.config.resourceDir
      dstResources = ctx.app_dir / "static"
    if srcResources.dirExists:
      ctx.log &"Copying resources from {srcResources} to {dstResources} ..."
      createDir(dstResources)
      copyDir(srcResources, dstResources)
  of PreCompile:
    discard
  of Compile:
    discard
  of PostCompile:
    discard
  of PreBuild:
    discard
  of Build:
    discard
  of PostBuild:
    discard
  of PrePackage:
    if not ctx.simulator:
      ctx.logStartStep
      # provisioning profile
      var prov_profile = getEnv(PROVISIONING_PROFILE_VARNAME, "")
      if prov_profile == "":
        let options = listProvisioningProfiles()
        if options.len > 0:
          debug &"Since {PROVISIONING_PROFILE_VARNAME} was not set, choosing a provisioning profile at random ..."
          prov_profile = options[0]
        else:
          raise newException(CatchableError, "No provisioning profile set.  Run 'wiish doctor' for instructions.")
      
      let dst = ctx.app_dir/"embedded.mobileprovision"
      ctx.log &"Copying '{prov_profile}' to '{dst}'"
      copyFile(prov_profile, dst)

      # Extract entitlements from provisioning profile and put them in the signature
      let prov_guts = prov_profile.readFile()
      let i_prestart = prov_guts.find("<key>Entitlements")
      let i_start = prov_guts.find("<dict>", i_prestart)
      let i_end = prov_guts.find("</dict>", i_start) + "</dict>".len
      let entitlements = prov_guts[i_start .. i_end]
      writeFile(ctx.entitlements_file, &"""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        {entitlements}
        </plist>
      """)
  of Package:
    discard
  of PostPackage:
    discard
  of PreSign:
    discard
  of BuildStep.Sign:
    if not ctx.simulator:
      ctx.logStartStep
      var signing_identity = getEnv(CODE_SIGN_IDENTITY_VARNAME, "")
      if signing_identity == "":
        let identities = listCodesigningIdentities()
        if identities.len > 0:
          debug &"Since {CODE_SIGN_IDENTITY_VARNAME} was not set, choosing a signing identity at random ..."
          signing_identity = identities[0].fullname

      if signing_identity == "":
        raise newException(CatchableError, "No signing identity chosen. Run 'wiish doctor' for instructions.")
      debug &"Signing app with identity {signing_identity}..."
      signApp(ctx.app_dir, signing_identity, ctx.entitlements_file)
      ctx.entitlements_file.removeFile()
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
      var p: Process
      ctx.logStartStep
      # open the simulator
      ctx.log "Opening simulator..."
      p = startProcess(command="open", args = @["-a", "Simulator"], options = {poUsePath, poParentStreams})
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

      # start the app
      ctx.log &"Starting app {ctx.config.bundle_identifier}..."
      let startmessage = shoutput("xcrun", "simctl", "launch", "booted", ctx.config.bundle_identifier)
      discard startmessage.strip.split(" ")[1]

      # Watch the logs
      var args = @["xcrun", "simctl", "spawn", "booted", "log", "stream"]
      # if not verbose:
      args.add(@["--predicate", &"subsystem contains \"{ctx.config.bundle_identifier}\""])
      sh(args)
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
#     DATADIR()/"ios-util"/"LaunchScreen.storyboard",
#     "--sdk", sdkPath,
#   )

#   debug &"Creating icons ..."
#   var iconSrcPath:string
#   if config.icon == "":
#     iconSrcPath = DATADIR()/"default_square.png"
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


proc checkDoctor*():seq[DoctorResult] =
  var cap:DoctorResult
  when defined(macosx):
    cap = DoctorResult(name: "ios/xcode")
    if findExe("xcrun") == "":
      cap.status = NotWorking
      cap.error = "xcode not found"
      cap.fix = "Install Xcode command line tools"
    else:
      cap.status = Working
    result.add(cap)

    cap = DoctorResult(name: "ios/signingkeys")
    let identities = listCodesigningIdentities().filterIt(it.fullname.startsWith("iPhone"))
    if identities.len == 0:
      cap.status = NotWorking
      cap.error = "No valid signing keys installed"
      cap.fix = "Obtain iPhone signing keys from Apple and install them in your keychain."
    else:
      cap.status = Working
    result.add(cap)

    cap = DoctorResult(name: "ios/chosenkey")
    if getEnv(CODE_SIGN_IDENTITY_VARNAME, "") == "":
      cap.status = NotWorking
      cap.error = "No identity chosen for iOS code signing"
      cap.fix = &"Set {CODE_SIGN_IDENTITY_VARNAME} to one of the options listed by 'security find-identity -v -p codesigning'"
      if identities.len > 0:
        cap.fix.add(&".  For instance: {CODE_SIGN_IDENTITY_VARNAME}='{identities[0].fullname}' might work.")
    else:
      cap.status = Working
    result.add(cap)

    cap = DoctorResult(name: "ios/provisioningprofile")
    if getEnv(PROVISIONING_PROFILE_VARNAME, "") == "":
      cap.status = NotWorking
      cap.error = "No provisioning profile chosen for iOS code signing"
      cap.fix = &"Set {PROVISIONING_PROFILE_VARNAME} to the path of a valid provisioning profile.  They can be found in '{PROV_PROFILE_DIR}' though they can also be downloaded from Apple."
      let possible_profiles = listProvisioningProfiles()
      if possible_profiles.len == 0:
        cap.fix.add("  You *might* be able to create such a profile by opening Xcode, creating a blank iOS project, enabling 'Automatically manage signing' and building the project once.  TODO: come up with less goofy instructions.")
      else:
        cap.fix.add(&"  For instance: {PROVISIONING_PROFILE_VARNAME}='{possible_profiles[0]}' might work.")
    else:
      cap.status = Working
    result.add(cap)
  else:
    result.add(DoctorResult(
      name: "ios",
      error: "iOS can only be built on the macOS operating system",
      fix: "Spend money to fix this",
    ))
  
    