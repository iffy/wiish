import sdl2 except Event, Rect
import opengl
import math
import macros
# import ../logging
import times
import ../wiishtypes
import ../../events

template sdlMain*() =
  when defined(ios) or defined(android):
    when not compileOption("noMain"):
      {.error: "Please run Nim with --noMain flag.".}
    
    when defined(ios):
      {.emit: "#define __IPHONEOS__".}

    {.emit: """
// The following piece of code is a copy-paste from SDL/SDL_main.h
// It is required to avoid dependency on SDL headers
////////////////////////////////////////////////////////////////////////////////


/**
 *  \file SDL_main.h
 *
 *  Redefine main() on some platforms so that it is called by SDL.
 */

 #ifndef SDL_MAIN_HANDLED
 #if defined(__WIN32__)
 /* On Windows SDL provides WinMain(), which parses the command line and passes
    the arguments to your main function.
 
    If you provide your own WinMain(), you may define SDL_MAIN_HANDLED
  */
 #define SDL_MAIN_AVAILABLE
 
 #elif defined(__WINRT__)
 /* On WinRT, SDL provides a main function that initializes CoreApplication,
    creating an instance of IFrameworkView in the process.
 
    Please note that #include'ing SDL_main.h is not enough to get a main()
    function working.  In non-XAML apps, the file,
    src/main/winrt/SDL_WinRT_main_NonXAML.cpp, or a copy of it, must be compiled
    into the app itself.  In XAML apps, the function, SDL_WinRTRunApp must be
    called, with a pointer to the Direct3D-hosted XAML control passed in.
 */
 #define SDL_MAIN_NEEDED
 
 #elif defined(__IPHONEOS__)
 /* On iOS SDL provides a main function that creates an application delegate
    and starts the iOS application run loop.
 
    See src/video/uikit/SDL_uikitappdelegate.m for more details.
  */
 #define SDL_MAIN_NEEDED
 
 #elif defined(__ANDROID__)
 /* On Android SDL provides a Java class in SDLActivity.java that is the
    main activity entry point.
 
    See README-android.txt for more details on extending that class.
  */
 #define SDL_MAIN_NEEDED
 
 #endif
 #endif /* SDL_MAIN_HANDLED */
 
 #ifdef __cplusplus
 #define C_LINKAGE   "C"
 #else
 #define C_LINKAGE
 #endif /* __cplusplus */
 
 /**
  *  \file SDL_main.h
  *
  *  The application's main() function must be called with C linkage,
  *  and should be declared like this:
  *  \code
  *  #ifdef __cplusplus
  *  extern "C"
  *  #endif
  *  int main(int argc, char *argv[])
  *  {
  *  }
  *  \endcode
  */
 #if defined(SDL_MAIN_NEEDED) || defined(SDL_MAIN_AVAILABLE)
 #define main    SDL_main
 #endif
 //#include <SDL2/SDL_main.h>
 extern int cmdCount;
 extern char** cmdLine;
 extern char** gEnv;
 N_CDECL(void, NimMain)(void);
 int main(int argc, char** args) {
     cmdLine = args;
     cmdCount = argc;
     gEnv = NULL;
     //`setupLogger`();
     NimMain();
     return nim_program_result;
 }
 
""".}

when defined(ios):
  {.passL: "-framework AudioToolbox" .}
  {.passC: "-framework AudioToolbox" .}
  {.passL: "-framework AVFoundation" .}
  {.passC: "-framework AVFoundation" .}
  {.passL: "-framework CoreAudio" .}
  {.passC: "-framework CoreAudio" .}
  {.passL: "-framework CoreGraphics" .}
  {.passC: "-framework CoreGraphics" .}
  {.passL: "-framework CoreMotion" .}
  {.passC: "-framework CoreMotion" .}
  {.passL: "-framework GameController" .}
  {.passC: "-framework GameController" .}
  {.passL: "-framework Metal" .}
  {.passC: "-framework Metal" .}
  {.passL: "-framework OpenGLES" .}
  {.passC: "-framework OpenGLES" .}
  {.passL: "-framework QuartzCore" .}
  {.passC: "-framework QuartzCore" .}
  {.passL: "-framework UIKit" .}
  {.passC: "-framework UIKit" .}
elif defined(macosx):
  {.passL: "-framework AudioToolbox" .}
  {.passC: "-framework AudioToolbox" .}
  {.passL: "-framework CoreAudio" .}
  {.passC: "-framework CoreAudio" .}
  {.passL: "-framework CoreGraphics" .}
  {.passC: "-framework CoreGraphics" .}
  {.passL: "-framework OpenGL" .}
  {.passC: "-framework OpenGL" .}
  {.passL: "-framework AppKit" .}
  {.passC: "-framework AppKit" .}
  {.passL: "-framework AudioUnit" .}
  {.passC: "-framework AudioUnit" .}
  {.passL: "-framework ForceFeedback" .}
  {.passC: "-framework ForceFeedback" .}
  {.passL: "-framework IOKit" .}
  {.passC: "-framework IOKit" .}
  {.passL: "-framework Carbon" .}
  {.passC: "-framework Carbon" .}
  {.passL: "-framework CoreServices" .}
  {.passC: "-framework CoreServices" .}
  {.passL: "-framework ApplicationServices" .}
  {.passC: "-framework ApplicationServices" .}
  {.passL: "-framework QuartzCore" .}
  {.passC: "-framework QuartzCore" .}


proc initSDLIfNeeded() =
    var sdlInitialized {.global.} = false
    if not sdlInitialized:
        if sdl2.init(INIT_VIDEO) != SdlSuccess:
            echo "Error: sdl2.init(INIT_VIDEO): ", getError()
        sdlInitialized = true
        
        if glSetAttribute(SDL_GL_STENCIL_SIZE, 8) != 0:
            echo "Error: could not set stencil size: ", getError()

        when defined(ios) or defined(android):
            discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, 0x0004)
            discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2)

# when defined(ios) or defined(android):
#     method fullscreen*(w: Window): bool = true
# else:
#     method fullscreenAvailable*(w: Window): bool = true
#     method fullscreen*(w: Window): bool = w.isFullscreen
#     method `fullscreen=`*(w: Window, v: bool) =
#         var res: SDL_Return = SdlError

#         if v and not w.isFullscreen:
#             res = w.sdlWindow.setFullscreen(SDL_WINDOW_FULLSCREEN_DESKTOP)
#         elif not v and w.isFullscreen:
#             res = w.sdlWindow.setFullscreen(0)

#         if res == SdlSuccess:
#             w.isFullscreen = v

# when defined(macosx) and not defined(ios):
#     import darwin/app_kit/nswindow
#     proc scaleFactor(w: Window): float32 =
#         var wminfo: WMInfo
#         discard w.sdlWindow.getWMInfo(wminfo)
#         let nsWindow = cast[ptr NSWindow](addr wminfo.padding[0])[]
#         assert(not nsWindow.isNil)
#         result = nsWindow.scaleFactor

# proc getSDLWindow*(wnd: Window): WindowPtr = wnd.impl

# var animationEnabled = false

# method animationStateChanged*(w: Window, state: bool) =
#     animationEnabled = state
#     when defined(ios):
#         if state:
#             proc animationCallback(p: pointer) {.cdecl.} =
#                 let w = cast[SdlWindow](p)
#                 w.runAnimations()
#                 w.drawWindow()
#             discard iPhoneSetAnimationCallback(w.sdlWindow, 0, animationCallback, cast[pointer](w))
#         else:
#             discard iPhoneSetAnimationCallback(w.sdlWindow, 0, nil, nil)

# SDL does not provide window id in touch event info, so we add this workaround
# assuming that touch devices may have only one window.
# var defaultWindow: Window

proc initCommon(w: Window) =
  if w.sdlWindow == nil:
    echo "Could not create window!"
    quit 1

  discard glSetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1)
  w.sdlGlContext = w.sdlWindow.glCreateContext()
  when not defined(ios):
    loadExtensions()
  if w.sdlGlContext == nil:
    echo "Could not create context!"
  discard glMakeCurrent(w.sdlWindow, w.sdlGlContext)
  glClearColor(45/255.0, 52/255.0, 54/255.0, 0)
  glClear(GL_COLOR_BUFFER_BIT)

proc initSdlWindow(w: Window, r: Rect)=
  w.sdlWindow = createWindow(nil, cint(r.x), cint(r.y), cint(r.width), cint(r.height), SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE or SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_HIDDEN)
  w.initCommon()

method init*(w: Window, r: Rect) =
  w.initSdlWindow(r)

method show*(w: Window)=
  if w.sdlWindow.isNil:
    w.initSdlWindow(w.frame)
    # w.setFrameOrigin zeroPoint

  w.sdlWindow.showWindow()
  w.sdlWindow.raiseWindow()

proc newWindow*(title:string = ""): Window =
  initSDLIfNeeded()
  result.new()
  app.windows.add(result)
  result.init(newRect(100, 200, 300, 400))
  result.sdlWindow.setTitle(title)
  result.show()



# method hide*(w: Window)=
#     var lx, ly: cint
#     w.sdlWindow.getPosition(lx, ly)
#     w.setFrameOrigin(newPoint(lx.Coord, ly.Coord))

#     mainApplication().removeWindow(w)
#     w.sdlWindow.destroyWindow()
#     w.sdlWindow = nil
#     w.sdlGlContext = nil
#     w.renderingContext = nil

# proc newWindow*(title:string = ""): Window =
#     result = newSdlWindow(newRect(100, 100, 200, 200))
#     result.show()

# newFullscreenWindow = proc(): Window =
#     result = newFullscreenSdlWindow()
#     result.show()

# method `title=`*(w: Window, t: string) =
#     w.sdlWindow.setTitle(t)

# method title*(w: Window): string = $w.sdlWindow.getTitle()

# method draw*(w: Window, r: sdl2.Rect) =
#     let c = currentContext()
#     let gl = c.gl
#     if w.mActiveBgColor != w.backgroundColor:
#         gl.clearColor(w.backgroundColor.r, w.backgroundColor.g, w.backgroundColor.b, w.backgroundColor.a)
#         w.mActiveBgColor = w.backgroundColor
#     gl.stencilMask(0xFF) # Android requires setting stencil mask to clear
#     gl.clear(gl.COLOR_BUFFER_BIT or gl.STENCIL_BUFFER_BIT or gl.DEPTH_BUFFER_BIT)
#     gl.stencilMask(0x00)

# proc drawCircle(cx:float, cy:float, r:float, segments:int = 32) =
#   glBegin(GL_LINE_LOOP)
#   for segment in 0..segments:
#     let theta = 2.0 * PI * segment.toFloat / segments.toFloat
#     let
#       x = r * cos(theta)
#       y = r * sin(theta)
#     glVertex2f(x + cx, y + cy)
#   glEnd()

proc drawWindow(w: Window) =
  discard glMakeCurrent(w.sdlWindow, w.sdlGlContext)
  
  # let c = w.renderingContext
  # let oldContext = setCurrentContext(c)

  glClearColor(45/255.0, 52/255.0, 54/255.0, 0)
  glClear(GL_COLOR_BUFFER_BIT)
  # glColor3f(0, 1, 0)
  # drawCircle(0, 0, 0.5)
  glFlush()
  w.onDraw.emit(newRect(0, 0, 0, 0))

  w.sdlWindow.glSwapWindow() # Swap the front and back frame buffers (double buffering)
  # setCurrentContext(oldContext)

# proc windowFromSDLEvent[T](event: T): Window =
#     let sdlWndId = event.windowID
#     let sdlWin = getWindowFromID(sdlWndId)
#     if sdlWin != nil:
#         result = cast[SdlWindow](sdlWin.getData("__nimx_wnd"))

# proc positionFromSDLEvent[T](event: T): auto =
#     newPoint(event.x.Coord, event.y.Coord)

# template buttonStateFromSDLState(s: KeyState): ButtonState =
#     if s == KeyPressed:
#         bsDown
#     else:
#         bsUp

# proc eventWithSDLEvent(event: ptr sdl2.Event): event.Event =
#     case event.kind:
#         of FingerMotion, FingerDown, FingerUp:
#             let bs = case event.kind
#                 of FingerDown: bsDown
#                 of FingerUp: bsUp
#                 else: bsUnknown

#             let touchEv = cast[TouchFingerEventPtr](event)
#             result = newTouchEvent(
#                                    newPoint(touchEv.x * defaultWindow.frame.width, touchEv.y * defaultWindow.frame.height),
#                                    bs, int(touchEv.fingerID), touchEv.timestamp
#                                    )
#             result.window = defaultWindow
#             when defined(macosx) and not defined(ios):
#                 result.kind = etUnknown # TODO: Fix apple trackpad problem

#         of WindowEvent:
#             let wndEv = cast[WindowEventPtr](event)
#             let wnd = windowFromSDLEvent(wndEv)
#             case wndEv.event:
#                 of WindowEvent_Resized:
#                     result = newEvent(etWindowResized)
#                     result.window = wnd
#                     result.position.x = wndEv.data1.Coord
#                     result.position.y = wndEv.data2.Coord
#                 of WindowEvent_FocusGained:
#                     wnd.onFocusChange(true)
#                 of WindowEvent_FocusLost:
#                     wnd.onFocusChange(false)
#                 of WindowEvent_Exposed:
#                     wnd.setNeedsDisplay()
#                 of WindowEvent_Close:
#                     if wnd.onClose.isNil:
#                         wnd.hide()
#                     else:
#                         wnd.onClose()
#                 else:
#                     discard

#         of MouseButtonDown, MouseButtonUp:
#             when not defined(ios) and not defined(android):
#                 if event.kind == MouseButtonDown:
#                     discard sdl2.captureMouse(True32)
#                 else:
#                     discard sdl2.captureMouse(False32)

#             let mouseEv = cast[MouseButtonEventPtr](event)
#             if mouseEv.which != SDL_TOUCH_MOUSEID:
#                 let wnd = windowFromSDLEvent(mouseEv)
#                 let state = buttonStateFromSDLState(mouseEv.state.KeyState)
#                 let button = case mouseEv.button:
#                     of sdl2.BUTTON_LEFT: VirtualKey.MouseButtonPrimary
#                     of sdl2.BUTTON_MIDDLE: VirtualKey.MouseButtonMiddle
#                     of sdl2.BUTTON_RIGHT: VirtualKey.MouseButtonSecondary
#                     else: VirtualKey.Unknown
#                 let pos = positionFromSDLEvent(mouseEv)
#                 result = newMouseButtonEvent(pos, button, state, mouseEv.timestamp)
#                 result.window = wnd

#         of MouseMotion:
#             let mouseEv = cast[MouseMotionEventPtr](event)
#             if mouseEv.which != SDL_TOUCH_MOUSEID:
#                 #echo("which: " & $mouseEv.which)
#                 let wnd = windowFromSDLEvent(mouseEv)
#                 if wnd != nil:
#                     let pos = positionFromSDLEvent(mouseEv)
#                     result = newMouseMoveEvent(pos, mouseEv.timestamp)
#                     result.window = wnd

#         of MouseWheel:
#             let mouseEv = cast[MouseWheelEventPtr](event)
#             let wnd = windowFromSDLEvent(mouseEv)
#             if wnd != nil:
#                 var x, y: cint
#                 getMouseState(x, y)
#                 let pos = newPoint(x.Coord, y.Coord)
#                 result = newEvent(etScroll, pos)
#                 result.window = wnd
#                 const multiplierX = when not defined(macosx): 30.0 else: 1.0
#                 const multiplierY = when not defined(macosx): -30.0 else: 1.0
#                 result.offset.x = mouseEv.x.Coord * multiplierX
#                 result.offset.y = mouseEv.y.Coord * multiplierY

#         of KeyDown, KeyUp:
#             let keyEv = cast[KeyboardEventPtr](event)
#             let wnd = windowFromSDLEvent(keyEv)
#             result = newKeyboardEvent(virtualKeyFromNative(cint(keyEv.keysym.scancode)), buttonStateFromSDLState(keyEv.state.KeyState), keyEv.repeat)
#             #result.rune = keyEv.keysym.unicode.Rune
#             result.window = wnd

#         of TextInput:
#             let textEv = cast[TextInputEventPtr](event)
#             result = newEvent(etTextInput)
#             result.window = windowFromSDLEvent(textEv)
#             result.text = $cast[cstring](addr textEv.text)

#         of TextEditing:
#             let textEv = cast[TextEditingEventPtr](event)
#             result = newEvent(etTextInput)
#             result.window = windowFromSDLEvent(textEv)
#             result.text = $cast[cstring](addr textEv.text)

#         of AppWillEnterBackground:
#             result = newEvent(etAppWillEnterBackground)

#         of AppWillEnterForeground:
#             result = newEvent(etAppWillEnterForeground)

#         else:
#             #echo "Unknown event: ", event.kind
#             discard

proc handleEvent(event: ptr sdl2.Event): Bool32 =
  var
    wiishEvent: wiishtypes.Event
  new(wiishEvent)
  case event.kind
  of sdl2.MouseButtonDown:
    wiishEvent.kind = wiishtypes.MouseButtonDown
  of sdl2.MouseButtonUp:
    wiishEvent.kind = wiishtypes.MouseButtonUp
  of sdl2.MouseMotion:
    wiishEvent.kind = wiishtypes.MouseMotion
  of sdl2.FingerDown:
    wiishEvent.kind = wiishtypes.FingerDown
  of sdl2.FingerUp:
    wiishEvent.kind = wiishtypes.FingerUp
  else:
    discard
  if wiishEvent.kind != Unknown:
    app.event.emit(wiishEvent)
    # if event.kind == UserEvent5:
    #     let evt = cast[UserEventPtr](event)
    #     let p = cast[proc (data: pointer) {.cdecl.}](evt.data1)
    #     if p.isNil:
    #         echo "WARNING: UserEvent5 with nil proc"
    #     else:
    #         p(evt.data2)
    # else:
    #     discard
    #     # This branch should never execute on a foreign thread!!!
    #     # var e = eventWithSDLEvent(event)
    #     # if (e.kind != etUnknown):
    #     #     discard mainApplication().handleEvent(e)
    # result = True32

# method onResize*(w: Window, newSize: Size) =
#     discard glMakeCurrent(w.sdlWindow, w.sdlGlContext)
#     procCall w.Window.onResize(newSize)
#     let constrainedSize = w.frame.size
#     if constrainedSize != newSize:
#         w.sdlWindow.setSize(constrainedSize.width.cint, constrainedSize.height.cint)
#     when defined(macosx) and not defined(ios):
#         w.pixelRatio = w.scaleFactor()
#     else:
#         w.pixelRatio = screenScaleFactor()
#     glViewport(0, 0, GLSizei(constrainedSize.width * w.pixelRatio), GLsizei(constrainedSize.height * w.pixelRatio))

# proc animateAndDraw() =
#     when not defined ios:
#         mainApplication().runAnimations()
#         mainApplication().drawWindows()
#     else:
#         if not animationEnabled:
#             mainApplication().runAnimations()
#             mainApplication().drawWindows()

# when defined(useRealtimeGC):
#     var lastFullCollectTime = 0.0
#     const fullCollectThreshold = 128 * 1024 * 1024 # 128 Megabytes

proc nextEvent(evt: var sdl2.Event) =
    # when not defined(useRealtimeGC):
    #     if gcRequested:
    #         info "GC_fullCollect"
    #         GC_fullCollect()
    #         gcRequested = false

    when defined(ios):
        proc iPhoneSetEventPump(enabled: Bool32) {.importc: "SDL_iPhoneSetEventPump".}

        iPhoneSetEventPump(true)
        pumpEvents()
        iPhoneSetEventPump(false)
        while pollEvent(evt):
            discard handleEvent(addr evt)

        # if not animationEnabled:
        #     mainApplication().drawWindows()
    else:
        var doPoll = false
        if waitEvent(evt):
          discard handleEvent(addr evt)
          doPoll = evt.kind != QuitEvent
        # if animationEnabled:
        #     doPoll = true
        # elif waitEvent(evt):
        #     discard handleEvent(addr evt)
        #     doPoll = evt.kind != QuitEvent
        # TODO: This should be researched more carefully.
        # During animations we need to process more than one event
        if doPoll:
            while pollEvent(evt):
                discard handleEvent(addr evt)
                if evt.kind == QuitEvent:
                    break
        for w in app.windows:
          w.drawWindow()
        # animateAndDraw()


    when defined(useRealtimeGC):
        let t = epochTime()
        if gcRequested or (t > lastFullCollectTime + 10 and getOccupiedMem() > fullCollectThreshold):
            GC_enable()
            GC_setMaxPause(0)
            GC_fullCollect()
            GC_disable()
            lastFullCollectTime = t
            gcRequested = false
        else:
            GC_step(1000, true)

# method startTextInput*(w: Window, r: sdl2.Rect) =
#     startTextInput()

# method stopTextInput*(w: Window) =
#     stopTextInput()

# when defined(macosx): # Most likely should be enabled for linux and windows...
#     # Handle live resize on macos
#     {.push stackTrace: off.} # This can be called on background thread
#     proc resizeEventWatch(userdata: pointer; event: ptr sdl2.Event): Bool32 {.cdecl.} =
#         if event.kind == WindowEvent:
#             let wndEv = cast[WindowEventPtr](event)
#             case wndEv.event
#             of WindowEvent_Resized:
#                 let wnd = windowFromSDLEvent(wndEv)
#                 var evt = newEvent(etWindowResized)
#                 evt.window = wnd
#                 evt.position.x = wndEv.data1.Coord
#                 evt.position.y = wndEv.data2.Coord
#                 discard mainApplication().handleEvent(evt)
#             else:
#                 discard
#     {.pop.}

template start*(app:App) =
  sdlMain()
  var evt = sdl2.Event(kind: UserEvent1)
  app.launched.emit(true)
  while true:
    nextEvent(evt)
    if evt.kind == QuitEvent:
      break

  app.willExit.emit(true)
  discard quit(evt)

proc quit*(app:App) =
  echo "NOT IMPLEMENTED"

