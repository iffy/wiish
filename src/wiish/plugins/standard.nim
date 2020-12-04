## Entrypoint for standard Wiish build plugin
import wiish/building/buildutil
import ./standard/build_macos
import ./standard/build_ios

type
  WiishBuild* = ref object
    ## Standard Wiish build plugin

proc name*(b: WiishBuild): string = "Wiish"

proc runStep*(b: WiishBuild, step: BuildStep, ctx: ref BuildContext) =
  case ctx.targetOS
  of Mac:
    macBuild(step, ctx)
  of Ios,IosSimulator:
    iosRunStep(step, ctx)
  else:
    ctx.log "Unable to build for: ", $ctx.targetOS
