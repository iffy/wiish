import wiish/build
import wiish/plugins/webview

wiishConfig = WiishConfig(
  name: when wiish_desktop: "Webview Demo" else: "Webview",
  version: "0.1.0",
  windowFormat: Webview,
  src: when wiish_desktop: "main_desktop.nim" else: "main_mobile.nim",
  outDir: "dist",
)
wiishConfig.add MacConfig(
  bundle_id: "com.wiish.webview"
)
wiishConfig.add MacDesktopConfig(
  category_type: "public.app-category.example"
)
build((
  WiishBuild(),
  WiishWebviewPlugin(),
))
