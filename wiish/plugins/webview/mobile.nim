## Module for making mobile Webview applications.
## Import from here regardless of the operating system.
import wiish/baseapp ; export baseapp
import wiish/common ; export common

type
  IWebviewWindow* = concept win
    ## This is the interface required for a webview window
    win.onReady is EventSource[bool]
    win.onMessage is EventSource[string]

  IWebviewMobileApp* = concept app
    ## This is the interface required for a webview mobile app
    app is IBaseApp
    newWebviewMobileApp() is ref IWebviewMobileApp
    app.start(url = string)
    app.life is EventSource[LifeEvent]
    app.getWindow(int) is ref IWebviewWindow

when wiish_dev and wiish_mobile:
  import ./mobile_dev
  export mobile_dev
elif defined(ios):
  import ./webview_ios
  export webview_ios
elif defined(android):
  import ./webview_android
  export webview_android
else:
  {.fatal: "No mobile OS chosen".}

# isConcept(IWebviewMobileApp, newWebviewMobileApp())
