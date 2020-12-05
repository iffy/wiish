## Entrypoint for standard Wiish build plugin
import wiish/building/buildutil
import wiish/doctor
import ./standard/build_macos
import ./standard/build_ios
import ./standard/build_android

type
  WiishBuild* = ref object
    ## Standard Wiish build plugin

proc name*(b: WiishBuild): string = "Wiish"

proc runStep*(b: WiishBuild, step: BuildStep, ctx: ref BuildContext) =
  ## Standard Wiish build
  case ctx.targetOS
  of Mac:
    macBuild(step, ctx)
  of Ios,IosSimulator:
    iosRunStep(step, ctx)
  of Android:
    androidRunStep(step, ctx)
  of MobileDev:
    discard
  else:
    ctx.log "Not yet supported: ", $ctx.targetOS

proc checkDoctor*(): seq[DoctorResult] =
  result.add build_ios.checkDoctor()
  result.add build_android.checkDoctor()
