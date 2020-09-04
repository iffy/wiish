import ../baseapp
export baseapp

type
  IWebviewMobileApp* = concept app
    ## This is the interface required for a webview mobile app
    app is IMobileApp
    newWebviewMobileApp() is typeof app
    app.start(url = string)
    app.life is MobileLifecycle
  
  IWebviewDesktopApp* = concept app
    ## These are the things needed for a webview desktop app
    app is IDesktopApp
    newWebviewDesktopApp() is app
    app.start(url = string)
    app.life is DesktopLifecycle
