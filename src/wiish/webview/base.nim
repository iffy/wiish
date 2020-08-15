import ../baseapp

type
  WebviewApp* = concept app
    discard
  
when defined(mobile):
  type
    WebviewMobileApp* = concept app
      app is WebviewApp
      app is MobileApp
      newWebviewApp() is app
else:
  type
    WebviewDesktopApp* = concept app
      app is WebviewApp
      app is DesktopApp
      newWebviewApp() is app

type
  WebviewWindow* = ref object of RootRef
    ## Reference to a single webview window
