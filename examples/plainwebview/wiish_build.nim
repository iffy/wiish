import wiish/build
import wiish/plugins/webview

var wb = WiishBuild(
  configure: proc(ctx: ref BuildContext) =
    var cfg = ctx.config
    cfg.name = if ctx.desktop: "Webview Demo" else: "Webview"
    cfg.version = "0.1.0"
    cfg.appWindowFormat = Webview
    cfg.src = if ctx.desktop: "main_desktop.nim" else: "main_mobile.nim"
    cfg.outDir = "dist"
    cfg.with(MacConfig, c):
      c.bundle_id = "com.wiish.webview"
    cfg.with(MacDesktopConfig, c):
      c.category_type = "public.app-category.example"
)
build((
  wb,
  WiishWebviewPlugin(),
))
