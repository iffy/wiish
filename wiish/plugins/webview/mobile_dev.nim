## Module for mobile dev build (e.g. a web page)
## This simulates what iOS and Android do
import tables
import std/exitprocs

import wiish/baseapp ; export baseapp
import ./desktop ; export desktop

type
  WebviewMobileApp* = object
    desktop: ref WebviewDesktopApp
    life*: EventSource[MobileEvent]
    windows: Table[int, ref WebviewWindow]

proc newWebviewMobileApp*(): ref WebviewMobileApp =
  new(result)
  result.desktop = newWebviewDesktopApp()
  result.life = newEventSource[MobileEvent]()
  result.windows = initTable[int, ref WebviewWindow]()

proc getWindow*(app: ref WebviewMobileApp, windowId: int): ref WebviewWindow {.inline.} =
  app.windows[windowId]

proc start*(app: ref WebviewMobileApp, url: string) =
  app.desktop.life.addListener proc(ev: DesktopEvent) =
    case ev.kind
    of desktopAppStarted:
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
    of desktopAppWillExit:
      discard "This is handled below in addExitProc"

  addExitProc proc() =
    for windowId in app.windows.keys:
      app.life.emit(MobileEvent(kind: WindowClosed, windowId: windowId))
    app.life.emit(MobileEvent(kind: AppWillExit))
  app.desktop.start()

