import wiish/build
import wiish/plugins/webview

var wb = WiishBuild(
  configure: proc(ctx: ref BuildContext) =
    var cfg = ctx.config
    cfg.name = if ctx.desktop: "Wiish Webview Demo" else: "WiishWebview"
    cfg.version = "0.1.0"
    cfg.src = "main.nim"
    cfg.outDir = "dist"
    cfg.appWindowFormat = Webview
    cfg.resourceDir = "resources"
    cfg.with(MacConfig, c):
      c.bundle_id = "org.wiish.webview"
    cfg.with(MacDesktopConfig, c):
      c.category_type = "public.app-category.example"
    cfg.with(MaciOSConfig, c):
      c.sdk_version = ""
      c.provisioning_profile_id = ""
    cfg.with(AndroidConfig, c):
      c.java_package_name = "org.wiish.webviewexample"
)

build((
  wb,
  WiishWebviewPlugin(),
))
