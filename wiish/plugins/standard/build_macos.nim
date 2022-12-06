import os
import strformat

import ./common
import wiish/building/config
import wiish/building/buildutil

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

proc contentsDir*(ctx: ref BuildContext): string {.inline.} =
  ## Return "MyApp.app/Contents" directory
  ctx.build_dir / ctx.config.name & ".app" / "Contents"

proc macBuild*(step: BuildStep, ctx: ref BuildContext) =
  ## Wiish Standard macOS Build
  case step
  of Setup:
    if ctx.targetFormat notin {targetMacApp, targetMacDMG}:
      return
    ctx.logStartStep()
    ctx.build_dir = ctx.projectPath / ctx.config.outDir / "macos"
    let contentsDir = ctx.contentsDir
    ctx.executable_path = contentsDir / "MacOS" / ctx.config.src.splitFile.name
    ctx.nim_flags.add ctx.config.nimFlags
    ctx.nim_flags.add "-d:appName=" & ctx.config.name
    
    ctx.log "mkdir ", contentsDir
    createDir(contentsDir)
    ctx.log "mkdir ", contentsDir/"Resources"
    createDir(contentsDir/"Resources")
    ctx.log "mkdir ", contentsDir/"MacOS"
    createDir(contentsDir/"MacOS")
    # Contents/PkgInfo
    ctx.log "create ", contentsDir/"PkgInfo"
    (contentsDir/"PkgInfo").writeFile("APPL????")
  of PreBuild:
    if ctx.targetFormat notin {targetMacApp, targetMacDMG}:
      return
    ctx.logStartStep()
    ctx.log "Generating .icns file ..."
    let
      iconDstPath = ctx.contentsDir/"Resources"/ctx.config.src.splitFile.name & ".icns"
    var iconSrcPath:string
    if ctx.config.iconPath == "":
      iconSrcPath = stdDataDir/default_icon
    else:
      iconSrcPath = ctx.projectPath/ctx.config.iconPath
    createICNS(iconSrcPath, iconDstPath)

    # Contents/Info.plist
    # <key>CFBundleIconFile</key>
    # <string>{executablePath}</string>
    (ctx.contentsDir/"Info.plist").writeFile(&"""
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>CFBundleAllowMixedLocalizations</key>
    <true/>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleExecutable</key>
    <string>{ctx.executable_path.extractFilename}</string>
    <key>CFBundleIdentifier</key>
    <string>{ctx.config.bundle_identifier}</string>
    <key>CFBundleIconFile</key>
    <string>{iconDstPath.extractFilename}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>{ctx.config.name}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>{ctx.config.version}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersionByArchitecture</key>
    <dict>
      <key>x86_64</key>
      <string>10.6</string>
    </dict>
    <key>LSRequiresCarbon</key>
    <true/>
    {ctx.config.info_plist_append}
  </dict>
  </plist>""")

    # Contents/Resources/resources
    let
      srcResources = ctx.projectPath/ctx.config.resourceDir
      dstResources = ctx.contentsDir/"Resources"/"resources"
    if srcResources.dirExists:
      ctx.log &"Copying resources from {srcResources} to {dstResources} ..."
      createDir(dstResources)
      copyDir(srcResources, dstResources)
      ctx.log &"Copy OK"
  else:
    discard

# proc doMacBuild*(directory:string, config: WiishConfig) {.deprecated.} =
#   ## Build a macOS .app
#   let
#     buildDir = directory/config.outDir/"macos"
#     appSrc = directory/config.src
#     appDir = buildDir/config.name & ".app"
#     contentsDir = appDir/"Contents"
#     executablePath = contentsDir/"MacOS"/appSrc.splitFile.name
#     srcResources = directory/config.resourceDir
#     dstResources = contentsDir/"Resources"/"resources"
  
#   createDir(contentsDir)
#   createDir(contentsDir/"Resources")
#   createDir(contentsDir/"MacOS")

#   # Contents/PkgInfo
#   (contentsDir/"PkgInfo").writeFile("APPL????")

#   # Compile Contents/MacOS/bin
#   var args = @[
#     "nim",
#     "c",
#     "-d:release",
#     "--gc:orc",
#     &"-d:appName={config.name}",
#   ]
#   args.add(config.nimflags)
#   args.add(&"-o:{executablePath}")
#   args.add(appSrc)
#   sh(args)

#   # Generate icons
#   debug "Generating .icns file ..."
#   var iconSrcPath:string
#   if config.iconPath == "":
#     iconSrcPath = stdDataDir/default_icon
#   else:
#     iconSrcPath = directory/config.iconPath
#   let iconDstPath = contentsDir/"Resources"/appSrc.splitFile.name & ".icns"
#   createICNS(iconSrcPath, iconDstPath)

#   # Contents/Info.plist
#   # <key>CFBundleIconFile</key>
#   # <string>{executablePath}</string>
#   (contentsDir/"Info.plist").writeFile(&"""
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
#   <key>CFBundleAllowMixedLocalizations</key>
#   <true/>
#   <key>CFBundleDevelopmentRegion</key>
#   <string>English</string>
#   <key>CFBundleExecutable</key>
#   <string>{executablePath.extractFilename}</string>
#   <key>CFBundleIdentifier</key>
#   <string>{config.bundle_identifier}</string>
#   <key>CFBundleIconFile</key>
#   <string>{iconDstPath.extractFilename}</string>
#   <key>CFBundleInfoDictionaryVersion</key>
#   <string>6.0</string>
#   <key>CFBundleName</key>
#   <string>{config.name}</string>
#   <key>CFBundlePackageType</key>
#   <string>APPL</string>
#   <key>CFBundleShortVersionString</key>
#   <string>{config.version}</string>
#   <key>NSHighResolutionCapable</key>
#   <true/>
#   <key>LSMinimumSystemVersionByArchitecture</key>
#   <dict>
#     <key>x86_64</key>
#     <string>10.6</string>
#   </dict>
#   <key>LSRequiresCarbon</key>
#   <true/>
# </dict>
# </plist>""")

#   # Contents/Resources/resources
#   if srcResources.dirExists:
#     debug &"Copying resources from {srcResources} to {dstResources} ..."
#     createDir(dstResources)
#     copyDir(srcResources, dstResources)

#   debug "ok"