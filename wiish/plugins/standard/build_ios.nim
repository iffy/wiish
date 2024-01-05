## Code for building iOS applications.
##
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
import times

import ./common
import wiish/doctor
import wiish/building/config
import wiish/building/buildutil

const
  CODE_SIGN_IDENTITY_VARNAME = "WIISH_IOS_SIGNING_IDENTITY"
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

proc getProvisioningProfileName(filename: string): string =
  var this_is_it = false
  for line in open(filename, fmRead).lines():
    if this_is_it:
      return line.replace(re".*?<string>(.*?)</string>.*?", "$1")
    elif "<key>name</key>" in line.toLower():
      this_is_it = true

proc app_dir*(ctx: ref BuildContext): string {.inline.} =
  ## Return the "MyApp.app" path
  ctx.dist_dir / ctx.config.name & ".app"

proc entitlements_file*(ctx: ref BuildContext): string {.inline.} =
  ctx.dist_dir / "Entitlements.plist"

type
  Replacement = tuple
    pattern: Regex
    replacement: string

proc replaceInFile(filename: string, replacements: seq[Replacement]) =
  ## Open a file, search for some patterns and perform the corresponding replacement
  # TODO: make this more efficient by not reading the whole file into memory
  var guts = readFile(filename)
  for (pattern,replacement) in replacements:
    guts = guts.replace(pattern, replacement)
  writeFile(filename, guts)

proc replaceInFile(filename: string, pattern: Regex, replacement: string) =
  filename.replaceInFile(@[(pattern, replacement)])

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
    ctx.dist_dir = ctx.projectPath / ctx.config.outDir / (if ctx.simulator: "ios-sim" else: "ios")
    ctx.build_dir = ctx.projectPath / "build" / "ios"
    ctx.executable_path = ctx.app_dir / "executable"
    ctx.nim_flags.add ctx.config.nimFlags
    ctx.nim_flags.add "-d:appBundleIdentifier=" & ctx.config.get(MacConfig).bundle_id
    if ctx.releaseBuild:
      ctx.nim_flags.add "-d:release"
    var sdk_version = ctx.config.get(MaciOSConfig).sdk_version
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
        for device in devices:
          ctx.log "Available device: " & device.name
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
    #   <string>{ctx.config.get(MacConfig).bundle_id}</string>
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
    if ctx.config.iconPath == "":
      iconSrcPath = stdDatadir / "default_square.png"
    else:
      iconSrcPath = ctx.projectPath / ctx.config.iconPath
    
    let xcassets = ctx.xcode_project_root / "wiishboilerplate" / "Assets.xcassets"
    let appicons = xcassets / "AppIcon.appiconset"

    proc fmtInt(x: float): string =
      if x.toInt.toFloat == x:
        $x.toInt
      else:
        $x
    
    proc fmtInt(x: int): string = $x

    proc addIcon(srcfile: string, size: int, scale: int, idioms = @["iphone", "ipad"], alpha = true) =
      let filename = appicons / &"Icon-{size}@{scale}x.png"
      let pixels = fmtInt(size.toFloat / scale.toFloat)
      let size_str = &"{pixels}x{pixels}"
      let scale_str = &"{scale}x"
      var contents_json = readFile(appicons / "Contents.json").parseJson()
      iconSrcPath.resizePNG(filename, size, size, removeAlpha = not alpha)
      var added: seq[string]
      for image in contents_json["images"]:
        let idiom = image["idiom"].getStr()
        let size = image["size"].getStr()
        let scale = image["scale"].getStr()
        if idiom in idioms and size == size_str and scale == scale_str:
          ctx.log "Added icon ", filename
          image["filename"] = newJString(filename.extractFilename())
          added.add(idiom)
      for idiom in idioms:
        if idiom notin added:
          ctx.log "Added icon ", filename
          contents_json["images"].add(%* {
            "size": size_str,
            "scale": scale_str,
            "idiom": idiom,
            "filename": newJString(filename.extractFilename()),
          })
      writeFile(appicons / "Contents.json", contents_json.pretty())

    # iOS icon guidelines: https://developer.apple.com/library/archive/qa/qa1686/_index.html
    iconSrcPath.addIcon(120, 2, @["iphone"])
    iconSrcPath.addIcon(180, 3, @["iphone"])
    iconSrcPath.addIcon(76, 1, @["ipad"])
    iconSrcPath.addIcon(152, 2, @["ipad"])
    iconSrcPath.addIcon(167, 2, @["ipad"])
    iconSrcPath.addIcon(1024, 1, @["ios-marketing"], alpha = false)
    # And the default icon
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
    
    # set build settings
    let pbxproj_path = ctx.xcode_project_file / "project.pbxproj"
    ctx.log &"Adjusting {pbxproj_path} ..."
    sh "plutil", "-convert", "json", pbxproj_path
    var pbx = readFile(pbxproj_path).parseJson()
    let build_version = now().format("yyyyMMddHHmmss")
    let provisioning_profile_id = ctx.config.get(MaciOSConfig).provisioning_profile_id
    for (key,obj) in pbx["objects"].pairs():
      var buildSettings = obj.getOrDefault("buildSettings")
      if not buildSettings.isNil:
        if buildSettings.hasKey("PRODUCT_BUNDLE_IDENTIFIER"):
          buildSettings["PRODUCT_BUNDLE_IDENTIFIER"] = % ctx.config.get(MacConfig).bundle_id
          ctx.log &"set PRODUCT_BUNDLE_IDENTIFIER to {ctx.config.get(MacConfig).bundle_id}"
        if buildSettings.hasKey("CURRENT_PROJECT_VERSION"):
          buildSettings["CURRENT_PROJECT_VERSION"] = % build_version
          ctx.log &"set CURRENT_PROJECT_VERSION to {build_version}" 
        if provisioning_profile_id != "":
          if buildSettings.hasKey("PROVISIONING_PROFILE_SPECIFIER"):
            buildSettings["PROVISIONING_PROFILE_SPECIFIER"] = % provisioning_profile_id
            ctx.log &"set PROVISIONING_PROFILE_SPECIFIER to {provisioning_profile_id}" 
      if obj.hasKey("productName"):
        obj["productName"] = % ctx.config.name
        ctx.log &"set productName to {ctx.config.name}"
        obj["name"] = % ctx.config.name
        ctx.log &"set name to {ctx.config.name}"
      if obj.hasKey("path"):
        if obj["path"].getStr().endsWith(".app"):
          obj["path"] = % &"{ctx.config.name}.app"
          ctx.log &"set app path to {ctx.config.name}.app"
    writeFile(pbxproj_path, $pbx)
    sh "plutil", "-convert", "xml1", pbxproj_path
    # pbxproj_path.replaceInFile(@[
    #   (re"PRODUCT_BUNDLE_IDENTIFIER = .*?;", &"PRODUCT_BUNDLE_IDENTIFIER = {ctx.config.get(MacConfig).bundle_id};"),
    #   (re"productName = .*?;", &"productName = {ctx.config.name};"),
    #   (re"; path = .*?\.app;", &"; path = \"{ctx.config.name}\";"),
    #   (re"""; path = ".*?\.app";""", &"; path = \"{ctx.config.name}\";"),
    # ])

    # list schemes
    block:
      ctx.log "listing schemes..."
      var args = @["xcodebuild",
        "-list",
        "-project", ctx.xcode_project_file,
        "-json",
      ]
      ctx.log args.join(" ")
      let outp = shoutput(args)
      ctx.log outp
      let data = parseJson(outp)
      let schemes = data{"project"}{"schemes"}.mapIt(it.getStr())
      if ctx.xcode_build_scheme notin schemes:
        ctx.log &"Chosen scheme {ctx.xcode_build_scheme} not valid"
        ctx.xcode_build_scheme = schemes[0]
        ctx.log &"Changed scheme to {ctx.xcode_build_scheme}"
  of Build:
    ctx.logStartStep()
    var args = @["xcodebuild",
      "-scheme", ctx.xcode_build_scheme,
      "-project", ctx.xcode_project_file,
      "-destination", ctx.xcode_build_destination,
      "-allowProvisioningUpdates",
      "clean",
    ]
    if ctx.targetFormat == targetIosIpa:
      args.add @[
        "-archivePath", ctx.dist_dir.absolutePath / ctx.config.name & ".xcarchive",
        "archive"
      ]
    else:
      args.add @[
        "build",
        "CONFIGURATION_BUILD_DIR=" & ctx.dist_dir.absolutePath,
      ]
    let prov_profile_id = ctx.config.get(MaciOSConfig).provisioning_profile_id
    if prov_profile_id != "":
      args.add @[
        "PROVISIONING_PROFILE=" & prov_profile_id
      ]
    ctx.log args.join(" ")
    sh(args)
  of PostBuild:
    if ctx.targetFormat == targetIosIpa:
      ctx.logStartStep()
      let export_plist_path = ctx.build_dir.absolutePath / "ExportOptions.plist"
      if not existsFile(export_plist_path):
        var prov_profile_name = ctx.config.get(MaciOSConfig).provisioning_profile_id
        export_plist_path.writeFile(fmt"""
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>uploadSymbols</key>
  <true/>
  <key>uploadBitcode</key>
  <false/>
  <key>signingStyle</key>
  <string>manual</string>
  <key>provisioningProfiles</key>
  <dict>
      <key>{ctx.config.get(MacConfig).bundle_id}</key>
      <string>{prov_profile_name}</string>
  </dict>
  <key>signingCertificate</key>
  <string>iOS Distribution</string>
</dict>
</plist>
        """)
      var args = @[
        "xcodebuild",
        "-exportArchive",
        "-archivePath", ctx.dist_dir.absolutePath / ctx.config.name & ".xcarchive",
        "-exportPath", ctx.dist_dir.absolutePath,
        "-exportOptionsPlist", export_plist_path,
      ]
      ctx.log args.join(" ")
      sh(args)
  of PrePackage:
    discard
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
        args.add(@["--predicate", &"subsystem contains \"{ctx.config.get(MacConfig).bundle_id}\""])
      var logp = startProcess(command=args[0], args = args[1..^1],
        options = {poUsePath, poParentStreams})

      # start the app
      ctx.log &"Starting app {ctx.config.get(MacConfig).bundle_id}..."
      let startmessage = shoutput("xcrun", "simctl", "launch", "booted", ctx.config.get(MacConfig).bundle_id)
      discard startmessage.strip.split(" ")[1]

      # wait for logs to finish
      discard logp.waitForExit()
      # sh(args)
    discard



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

    security find-identity -v -p codesigning
  
  """
        if identities.len > 0:
          dr.fix.add(&"For instance: {CODE_SIGN_IDENTITY_VARNAME}='{identities[0].fullname}' might work.")

  #   result.dr "standard", "provisioning-profile":
  #     dr.targetOS = {Ios}
  #     if getEnv(PROVISIONING_PROFILE_VARNAME, "") == "":
  #       dr.status = NotWorking
  #       dr.error = "No provisioning profile chosen for iOS code signing"
  #       dr.fix = &"""Set {PROVISIONING_PROFILE_VARNAME} to the path of a valid provisioning profile.  They can be found in '{PROV_PROFILE_DIR}'"""
  #       let possible_profiles = listProvisioningProfiles()
  #       if possible_profiles.len == 0:
  #         dr.fix.add("""
  # You *might* be able to create such a profile by:
  # 1. Opening Xcode
  # 2. Creating a blank iOS project
  # 3. Enabling 'Automatically manage signing'
  # 4. Building the project once.

  # TODO: come up with less goofy instructions.""")
  #       else:
  #         dr.fix.add(" Here are the profiles wiish can identify:\l\l")
  #         for prof in possible_profiles:
  #           dr.fix.add(&"   {prof.extractFilename()} '{prof.getProvisioningProfileNAme()}'\l")
  else:
    result.dr "standard", "os":
      dr.targetOS = {Ios,IosSimulator}
      dr.status = NotWorkingButOptional
      dr.error = "iOS can only be built on the macOS operating system"
      dr.fix = "Give money to Apple to fix this"
  
    