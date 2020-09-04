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
  testconcepts* = defined(testconcepts)

template isConcept*(con: untyped, instance: untyped): untyped =
  ## Check if the given concept is fulfilled by the instance.
  when testconcepts:
    {.hint: "Checking concept: " & $con .}
    block:
      proc checkConcept(ign: con) {.used.} = discard
      checkConcept(instance) {.explain.}

type
  MobileLifecycle* = ref object of RootRef
    ## Object onto which you can register handlers related
    ## to a mobile application's lifecycle events
    onCreate*: EventSource[bool]
    onStart*: EventSource[bool]
    onResume*: EventSource[bool]
    onPause*: EventSource[bool]
    onStop*: EventSource[bool]
    onDestroy*: EventSource[bool]
  
  DesktopLifecycle* = ref object of RootRef
    ## Object onto which you can register handlers related
    ## to a desktop application's lifecycle events
    onStart*: EventSource[bool]
    onBeforeExit*: EventSource[bool]

proc newMobileLifecycle*(): MobileLifecycle =
  new(result)
  result.onCreate = newEventSource[bool]()
  result.onStart = newEventSource[bool]()
  result.onResume = newEventSource[bool]()
  result.onPause = newEventSource[bool]()
  result.onStop = newEventSource[bool]()
  result.onDestroy = newEventSource[bool]()

proc newDesktopLifecycle*(): DesktopLifecycle =
  new(result)
  result.onStart = newEventSource[bool]()
  result.onBeforeExit = newEventSource[bool]()

# iOS <12 events
# https://developer.apple.com/documentation/uikit/uiapplicationdelegate
# - didFinishLaunching
# - didBecomeActive
# - willResignActive
# - didEnterBackground
# - willEnterForeground
# - willTerminate

# iOS >=13 events (application still has the above, but also has the below)
# https://developer.apple.com/documentation/uikit/uiscenedelegate
# - sceneAdded
# - sceneDidDisconnect
# - sceneWillEnterForeground
# - sceneDidBecomeActive
# - sceneWillResignActive
# - sceneDidEnterBackground

# Android
# https://developer.android.com/guide/components/activities/activity-lifecycle
# - onCreate
# - onStart
# - onResume
# - onPause
# - onStop
# - onDestroy

type
  IBaseApp* = concept app
    ## Interface common to both mobile and desktop applications

  IDesktopApp* = concept app
    ## Interface required for desktop applications
    app is IBaseApp
    app.life is DesktopLifecycle

  IMobileApp* = concept app
    ## Interface required for mobile applications
    app is IBaseApp
    app.life is MobileLifecycle