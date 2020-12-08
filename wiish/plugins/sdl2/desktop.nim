## Module for making desktop SDL2 applications
import tables
import sdl2

import wiish/events ; export events
import wiish/logsetup
import wiish/baseapp ; export baseapp
import wiish/common as wiish_common ; export wiish_common

import ./common; export common

type
  SDL2DesktopApp* = ref object
    windows*: Table[int, SDL2Window]
    nextWindowId*: int
    life*: EventSource[DesktopEvent]
    sdlEvent*: EventSource[sdl2.Event]
  
proc newSDL2DesktopApp*(): SDL2DesktopApp =
  new(result)
  result[].life = newEventSource[DesktopEvent]()

template start*(app: SDL2DesktopApp) =
  startLogging()
  sdlMain()
  var evt = sdl2.defaultEvent
  app.life.emit(DesktopEvent(kind: desktopAppStarted))
  while true:
    nextEvent(app, evt)
    case evt.kind
    of QuitEvent:
      break
    else:
      discard
  app.life.emit(DesktopEvent(kind: desktopAppWillExit))
  sdl2.quit()
  quit(0)
  
isConcept(IDesktopApp, newSDL2DesktopApp())