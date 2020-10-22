## Module for mobile dev build (e.g. a web page)
## This simulates what iOS and Android do
import ./base
import ./desktop
export desktop
import logging
import tables
import std/exitprocs

type
  WebviewMobileApp* = ref object of RootRef
    desktop: WebviewDesktopApp
    life*: EventSource[MobileEvent]
    windows: Table[int, WebviewWindow]

proc newWebviewMobileApp*(): WebviewMobileApp =
  new(result)
  result.desktop = newWebviewDesktopApp()
  result.life = newEventSource[MobileEvent]()
  result.windows = initTable[int, WebviewWindow]()

proc getWindow*(app: WebviewMobileApp, windowId: int): WebviewWindow {.inline.} =
  app.windows[windowId]

proc start*(app: WebviewMobileApp, url: string) =
  app.desktop.life.onStart.handle:
    app.life.emit(MobileEvent(kind: AppStarted))

    let window = app.desktop.newWindow(
      title = "Wiish Mobile Dev",
      url = url,
      width = 375,
      height = 667,
    )
    let windowId = 0
    app.windows[windowId] = window
    app.life.emit(MobileEvent(kind: WindowAdded, windowId: windowId))
    app.life.emit(MobileEvent(kind: WindowWillForeground, windowId: windowId))
    app.life.emit(MobileEvent(kind: WindowDidForeground, windowId: windowId))
    # window.onMessage.handle(message):
    #   debug "MATT: desktop.window.onMessage: " & message
    # window.onReady.handle:
    #   debug "MATT: window.onReady"

  addExitProc proc() =
    for windowId in app.windows.keys:
      app.life.emit(MobileEvent(kind: WindowClosed, windowId: windowId))
    app.life.emit(MobileEvent(kind: AppWillExit))
  app.desktop.start()

