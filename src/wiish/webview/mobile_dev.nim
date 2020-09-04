## Module for mobile dev build (e.g. a web page)
import ./base
import ./desktop
import logging

type
  WebviewMobileApp* = ref object of RootRef
    desktop: WebviewDesktopApp
    life*: MobileLifecycle

proc newWebviewMobileApp*(): WebviewMobileApp =
  new(result)
  result.desktop = newWebviewDesktopApp()
  result.life = newMobileLifecycle()

proc start*(app: WebviewMobileApp, url: string) =
  app.desktop.life.onStart.handle:
    debug "desktop.onStart"
    let window = app.desktop.newWindow(
      title = "Mobile",
      url = url,
      width = 375,
      height = 667,
    )
    app.life.onCreate.emit(true)
    window.onMessage.handle(message):
      debug "desktop.window.onMessage: " & message
    window.onReady.handle:
      debug "desktop.window.onReady"
      app.life.onStart.emit(true)

  app.desktop.start()

