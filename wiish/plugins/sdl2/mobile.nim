## Module for making mobile SDL2 applications
import tables
import sdl2

import wiish/events ; export events
import wiish/logsetup
import wiish/baseapp ; export baseapp
import wiish/common as wiish_common ; export wiish_common

import ./common; export common

type
  SDL2MobileApp* = ref object
    windows*: Table[int, SDL2Window]
    nextWindowId*: int
    life*: EventSource[LifeEvent]
    sdlEvent*: EventSource[sdl2.Event]

proc newSDL2MobileApp*(): SDL2MobileApp =
  new(result)
  result[].life = newEventSource[LifeEvent]()

template start*(app: SDL2MobileApp) =
  startLogging()
  sdlMain()
  var evt = sdl2.defaultEvent
  app.life.emit(LifeEvent(kind: AppStarted))
  while true:
    nextEvent(app, evt)
    case evt.kind
    of QuitEvent:
      break
    else:
      discard
  app.life.emit(LifeEvent(kind: AppWillExit))
  sdl2.quit()
  quit(0)
  
# isConcept(IMobileApp, newSDL2MobileApp())