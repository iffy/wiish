import ./events; export events

const
  wiish_dev* = defined(wiish_dev) or defined(wiish_mobiledev)
    ## Indicates that this isn't a packaged app, but rather running in dev mode
  wiish_ios* = defined(ios)
  wiish_android* = defined(android)
  wiish_mobiledev* = defined(wiish_mobiledev)
  wiish_mobile* = wiish_ios or wiish_android or wiish_mobiledev
    ## Indicates that this is mobile app
  wiish_mac* = defined(macosx) and not wiish_mobile
  wiish_linux* = defined(linux) and not wiish_mobile
  wiish_windows* = defined(windows) and not wiish_mobile
  wiish_desktop* = not wiish_mobile
    ## Indicates that this is a desktop app
  testconcepts* = defined(testconcepts)

# template isConcept*(con: untyped, instance: untyped): untyped =
#   ## Check if the given concept is fulfilled by the instance.
#   when testconcepts:
#     {.hint: "Checking concept: " & $con .}
#     block:
#       proc checkConcept[T: con](ign: T) {.used.} = discard
#       checkConcept(instance) {.explain.}

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
  LifeEventKind* = enum
    AppStarted
    AppWillExit
    WindowAdded
    WindowWillForeground ## Mobile only
    WindowDidForeground ## Mobile only
    WindowWillBackground ## Mobile only
    WindowClosed

  LifeEvent* = object
    ## Events that can happen to mobile apps
    case kind*: LifeEventKind
    of AppStarted, AppWillExit:
      discard
    of WindowAdded, WindowWillForeground, WindowDidForeground, WindowWillBackground, WindowClosed:
      windowId*: int

type
  IBaseApp* = concept app
    ## Interface common to both mobile and desktop applications
    app.life is EventSource[LifeEvent]
