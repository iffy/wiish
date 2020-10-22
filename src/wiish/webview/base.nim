import ../baseapp
export baseapp

type
  IWebviewWindow* = concept win
    ## This is the interface required for a webview window
    win.onReady is EventSource[bool]
    win.onMessage is EventSource[string]

  IWebviewMobileApp* = concept app
    ## This is the interface required for a webview mobile app
    app is IMobileApp
    newWebviewMobileApp() is typeof app
    app.start(url = string)
    app.life is EventSource[MobileEvent]
    app.getWindow(int) is IWebviewWindow
  
  IWebviewDesktopApp* = concept app
    ## These are the things needed for a webview desktop app
    app is IDesktopApp
    newWebviewDesktopApp() is app
    app.start(url = string)
    app.life is DesktopLifecycle
