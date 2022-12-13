## Entrypoint for standard Wiish build plugin
import os

import wiish/building/config
import wiish/building/buildutil
import ./standard/build_macos
import ./standard/build_ios
import ./standard/build_android

type
  WiishBuild* = ref object
    ## Standard Wiish build plugin
    configure*: proc(ctx: ref BuildContext)

proc name*(b: WiishBuild): string = "Wiish"

proc runStep*(b: WiishBuild, step: BuildStep, ctx: ref BuildContext) =
  ## Standard Wiish build
  if step == Setup:
    ctx.log "Generating config..."
    ctx.config = wiishConfig
    if b.configure.isNil:
      raise ValueError.newException("You must provide a `configure` proc to WiishBuild")
    b.configure(ctx)
    ctx.log "Config: " & $ctx.config
    ctx.log "MacConfig: " & $ctx.config.get(MacConfig)
    ctx.log "MacDesktopConfig: " & $ctx.config.get(MacDesktopConfig)
    ctx.log "MaciOSConfig: " & $ctx.config.get(MaciOSConfig)
    ctx.log "AndroidConfig: " & $ctx.config.get(AndroidConfig)

  if ctx.targetFormat == targetRun and step == Run:
    ctx.log "WIISH RUN STARTING" # This is a signal that tests count on
    ctx.log "PID ", $getCurrentProcessId()
    ctx.nim_run_flags.add "-d:wiish_dev"
  case ctx.targetOS
  of Mac:
    macBuild(step, ctx)
  of Ios,IosSimulator:
    iosRunStep(step, ctx)
  of Android:
    androidRunStep(step, ctx)
  of MobileDev:
    if step == Setup:
      ctx.nim_run_flags.add "-d:wiish_mobiledev"
  of Linux:
    ctx.log "Linux not fully supported yet"
  else:
    raise ValueError.newException("Not yet supported: " & $ctx.targetOS)
  
