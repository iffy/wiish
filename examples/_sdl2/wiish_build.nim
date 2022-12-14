import wiish/build
import wiish/plugins/sdl2

var wb = WiishBuild(
  configure: proc(ctx: ref BuildContext) =
    var cfg = ctx.config
    cfg.name = if ctx.desktop: "Wiish SDL Demo" else: "WiishSDL"
    cfg.version = "0.1.0"
    cfg.src = if ctx.desktop: "main_desktop.nim" else: "main_mobile.nim"
    cfg.outDir = "dist"
    cfg.appWindowFormat = SDL
    cfg.with(MacConfig, c):
      c.bundle_id = "org.wiish.sdlexample"
    cfg.with(MacDesktopConfig, c):
      c.category_type = "public.app-category.example"
    cfg.with(MaciOSConfig, c):
      c.sdk_version = ""
      c.provisioning_profile = ""
    cfg.with(AndroidConfig, c):
      c.java_package_name = "org.wiish.sdlexample"
)

build((
  wb,
  WiishSDL2Plugin(),
))
