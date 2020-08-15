import ./events
import os

const
  wiish_dev* = defined(wiish_dev) or defined(wiish_mobiledev)
    ## Indicates that this isn't a packaged app, but rather running in dev mode
  wiish_mobile* = defined(ios) or defined(android) or defined(wiish_mobiledev)
    ## Indicates that this is mobile app
  wiish_desktop* = not wiish_mobile
    ## Indicates that this is a desktop app
  wiish_webview* = defined(wiish_webview)
    ## Indicates that this is a webview app
  wiish_sdl* = defined(wiish_sdl)
    ## Indicates that this is an SDL2 app

type
  BaseApp* = concept app
    ## Interface common to both mobile and desktop applications
    discard

  DesktopApp* = concept app
    ## Interface required for desktop applications
    app is BaseApp
    app.launched is EventSource[bool]
    app.willExit is EventSource[bool]

  MobileApp* = concept app
    ## Interface required for mobile applications
    app is BaseApp

  BaseApplication* = ref object of RootRef
    ## This is the base application for all Wiish applications
    ## 
    ## Different implementations
    launched*: EventSource[bool]
    willExit*: EventSource[bool]
  
  BaseWindow* = ref object of RootRef

assert BaseApplication is BaseApp


when wiish_dev:
  import ./building/config
  proc resourcePath*(app: BaseApplication, filename: string): string =
    ## Return the path to a static resource included in the application
    let
      appdir = getAppDir()
      configPath = appdir/"wiish.toml"
      config = getMyOSConfig(configPath)
    result = joinPath(appdir, config.resourceDir, filename) # XXX this is not safe from going above resourcePath
else:
  proc resourcePath*(app: BaseApplication, filename: string): string =
    ## Return the path to a static resource included in the application
    let
      root = 
        when defined(ios):
          getAppDir()/"static"
        elif defined(android):
          "/android_asset"
        elif defined(macosx):
          normalizedPath(getAppDir()/"../Resources/resources").absolutePath()
        else:
          getAppDir()
    result = joinPath(root, filename) # XXX this is not safe from going above resourcePath
