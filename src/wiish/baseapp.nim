import ./events; export events
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

## For iOS related documentation see:
##
## - Overview: https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle?language=objc
## - UIApplicationDelegate: https://developer.apple.com/documentation/uikit/uiapplicationdelegate?language=objc
## - UISceneDelegate: https://developer.apple.com/documentation/uikit/uiscenedelegate?language=objc
## - Scenes: https://developer.apple.com/documentation/uikit/app_and_environment/scenes?language=objc
##
## For Android, TODO
## - Overview: https://developer.android.com/guide/components/activities/activity-lifecycle
## - 

type
  MobileEventKind* = enum
    AppStarted
      ## iOS      UIApplicationDelegate didFinishLaunchingWithOptions 
      ## Android  TODO
    AppWillExit
      ## iOS      UIApplicationDelegate applicationWillTerminate
      ## Android  TODO
    WindowAdded
      ## iOS 13   UISceneDelegate willConnectToSession
      ## Android  TODO
    WindowWillForeground
      ## iOS 13   UISceneDelegate sceneWillEnterForeground
      ## Android  TODO
    WindowDidForeground
      ## iOS 13   UISceneDelegate sceneDidBecomeActive
      ## Android  TODO
    WindowWillBackground
      ## iOS 13   UISceneDelegate sceneWillResignActive
      ## Android  TODO
    WindowClosed
      ## iOS 13   UISceneDelegate sceneDidDisconnect
      ## Android  TODO

  MobileEvent* = object
    ## Events that can happen to mobile apps
    case kind*: MobileEventKind
    of AppStarted, AppWillExit:
      discard
    of WindowAdded, WindowWillForeground, WindowDidForeground, WindowWillBackground, WindowClosed:
      windowId*: int

  DesktopLifecycle* = ref object of RootRef
    ## Object onto which you can register handlers related
    ## to a desktop application's lifecycle events
    onStart*: EventSource[bool]
    onBeforeExit*: EventSource[bool]

proc newDesktopLifecycle*(): DesktopLifecycle =
  new(result)
  result.onStart = newEventSource[bool]()
  result.onBeforeExit = newEventSource[bool]()

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
    app.life is EventSource[MobileEvent]
