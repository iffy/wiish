import os
import strformat
import parsetoml
import posix
import logging

import ./config
import ./buildutil

const
  default_icon = "default.png"

proc createICNS*(srcfile:string, output:string) =
  ## Create an ICNS icon pack from a source image
  if srcfile.splitFile.ext == ".icns":
    # It's already an icns
    copyDir(srcfile, output)
  else:
    # Convert it
    let
      iconsetPath = output.parentDir/"tmp.iconset"
    createDir(iconsetPath)
    srcfile.resizePNG(iconsetPath/"icon_512x512@2x.png", 1024, 1024)
    srcfile.resizePNG(iconsetPath/"icon_512x512.png", 512, 512)
    srcfile.resizePNG(iconsetPath/"icon_256x256@2x.png", 512, 512)
    srcfile.resizePNG(iconsetPath/"icon_256x256.png", 256, 256)
    srcfile.resizePNG(iconsetPath/"icon_128x128@2x.png", 256, 256)
    srcfile.resizePNG(iconsetPath/"icon_128x128.png", 128, 128)
    srcfile.resizePNG(iconsetPath/"icon_32x32@2x.png", 64, 64)
    srcfile.resizePNG(iconsetPath/"icon_32x32.png", 32, 32)
    srcfile.resizePNG(iconsetPath/"icon_16x16@2x.png", 32, 32)
    srcfile.resizePNG(iconsetPath/"icon_16x16.png", 16, 16)
    sh("iconutil", "-c", "icns", "--output", output, iconsetPath)
    removeDir(iconsetPath)

proc macBuild*(step: BuildStep, ctx: ref BuildContext) =
  ## Perform a single step of a generic macOS build
  let
    directory = ctx.projectPath
    config = ctx.config
    buildDir = directory/config.dst/"macos"
    appSrc = directory/config.src
    appDir = buildDir/config.name & ".app"
    contentsDir = appDir/"Contents"
    executablePath = contentsDir/"MacOS"/appSrc.splitFile.name
    srcResources = directory/config.resourceDir
    dstResources = contentsDir/"Resources"/"resources"
    iconDstPath = contentsDir/"Resources"/appSrc.splitFile.name & ".icns"

  case step
  of PreBuild:
    discard
  of PreCompileTargetConfig:
    createDir(contentsDir)
    createDir(contentsDir/"Resources")
    createDir(contentsDir/"MacOS")
    # Contents/PkgInfo
    (contentsDir/"PkgInfo").writeFile("APPL????")
  of CompileNim:
    # Compile Contents/MacOS/bin
    var args = @[
      "nim",
      "c",
      "-d:release",
      "--gc:orc",
      &"-d:appName={config.name}",
    ]
    args.add(config.nimflags)
    args.add(&"-o:{executablePath}")
    args.add(appSrc)
    sh(args)
  of BuildIcons:
    debug "Generating .icns file ..."
    var iconSrcPath:string
    if config.icon == "":
      iconSrcPath = DATADIR()/default_icon
    else:
      iconSrcPath = directory/config.icon
    createICNS(iconSrcPath, iconDstPath)
  of PostCompileTargetConfig:
    # Contents/Info.plist
    # <key>CFBundleIconFile</key>
    # <string>{executablePath}</string>
    (contentsDir/"Info.plist").writeFile(&"""
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>CFBundleAllowMixedLocalizations</key>
    <true/>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleExecutable</key>
    <string>{executablePath.extractFilename}</string>
    <key>CFBundleIdentifier</key>
    <string>{config.bundle_identifier}</string>
    <key>CFBundleIconFile</key>
    <string>{iconDstPath.extractFilename}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>{config.name}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>{config.version}</string>
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
  of EmbedResources:
    # Contents/Resources/resources
    if srcResources.dirExists:
      debug &"Copying resources from {srcResources} to {dstResources} ..."
      createDir(dstResources)
      copyDir(srcResources, dstResources)
  of PostBuild:
    discard
  of Package:
    discard
  of SignPackage:
    discard
  of NotarizePackage:
    discard
  of Run:
    discard

proc doMacBuild*(directory:string, config: WiishConfig) =
  ## Build a macOS .app
  let
    buildDir = directory/config.dst/"macos"
    appSrc = directory/config.src
    appDir = buildDir/config.name & ".app"
    contentsDir = appDir/"Contents"
    executablePath = contentsDir/"MacOS"/appSrc.splitFile.name
    srcResources = directory/config.resourceDir
    dstResources = contentsDir/"Resources"/"resources"
  
  createDir(contentsDir)
  createDir(contentsDir/"Resources")
  createDir(contentsDir/"MacOS")

  # Contents/PkgInfo
  (contentsDir/"PkgInfo").writeFile("APPL????")

  # Compile Contents/MacOS/bin
  var args = @[
    "nim",
    "c",
    "-d:release",
    "--gc:orc",
    &"-d:appName={config.name}",
  ]
  args.add(config.nimflags)
  args.add(&"-o:{executablePath}")
  args.add(appSrc)
  sh(args)

  # Generate icons
  debug "Generating .icns file ..."
  var iconSrcPath:string
  if config.icon == "":
    iconSrcPath = DATADIR()/default_icon
  else:
    iconSrcPath = directory/config.icon
  let iconDstPath = contentsDir/"Resources"/appSrc.splitFile.name & ".icns"
  createICNS(iconSrcPath, iconDstPath)

  # Contents/Info.plist
  # <key>CFBundleIconFile</key>
  # <string>{executablePath}</string>
  (contentsDir/"Info.plist").writeFile(&"""
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleAllowMixedLocalizations</key>
  <true/>
  <key>CFBundleDevelopmentRegion</key>
  <string>English</string>
  <key>CFBundleExecutable</key>
  <string>{executablePath.extractFilename}</string>
  <key>CFBundleIdentifier</key>
  <string>{config.bundle_identifier}</string>
  <key>CFBundleIconFile</key>
  <string>{iconDstPath.extractFilename}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>{config.name}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>{config.version}</string>
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

  # Contents/Resources/resources
  if srcResources.dirExists:
    debug &"Copying resources from {srcResources} to {dstResources} ..."
    createDir(dstResources)
    copyDir(srcResources, dstResources)

  debug "ok"