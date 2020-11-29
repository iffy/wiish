import ./build; export build

type
  WiishWebviewBuild* = object

proc name*(b: WiishWebviewBuild): string = "WiishWebview"

proc runStep*(b: WiishWebviewBuild, step: BuildStep, ctx: ref BuildContext) =
  case ctx.targetOS
  of Mac:
    let
      directory = ctx.projectPath
      config = ctx.config
      buildDir = directory/config.dst/"macos"
      appSrc = directory/config.src
      appDir = buildDir/config.name & ".app"
      contentsDir = appDir/"Contents"
      executablePath = contentsDir/"MacOS"/appSrc.splitFile.name
    
    case step
    of CompileNim:
        # Compile Contents/MacOS/bin
        var args = @[
          "nim",
          "c",
          "-d:release",
          "--gc:orc",
          &"-d:appName={ctx.config.name}",
        ]
        args.add(ctx.config.nimflags)
        args.add(&"-o:{executablePath}")
        args.add(appSrc)
        sh(args)
    else:
      discard
  else:
    echo "Unable to compile for: ", $ctx.targetOS

