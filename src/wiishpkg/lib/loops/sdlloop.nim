## This module provides functions for creating SDL windows
## and listening for events
import sdl2 except Event, Rect
import opengl
import macros
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

proc initSdlWindow(w: Window, r: Rect)=
  w.sdlWindow = createWindow(nil, cint(r.x), cint(r.y), cint(r.width), cint(r.height), SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE or SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_HIDDEN)
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

proc show*(w: Window)=
  if w.sdlWindow.isNil:
    w.initSdlWindow(w.frame)
    # w.setFrameOrigin zeroPoint

  w.sdlWindow.showWindow()
  w.sdlWindow.raiseWindow()

proc newWindow*(title:string = ""): Window =
  initSDLIfNeeded()
  result.new()
  app.windows.add(result)
  result.initSdlWindow(newRect(100, 200, 300, 400))
  result.sdlWindow.setTitle(title)
  result.show()

proc drawWindow(w: Window) =
  discard glMakeCurrent(w.sdlWindow, w.sdlGlContext)
  glClearColor(45/255.0, 52/255.0, 54/255.0, 0)
  glClear(GL_COLOR_BUFFER_BIT)
  glFlush()
  w.onDraw.emit(newRect(0, 0, 0, 0))
  w.sdlWindow.glSwapWindow()

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

proc nextEvent(evt: var sdl2.Event) =
  var doPoll = false
  if waitEvent(evt):
    discard handleEvent(addr evt)
    doPoll = evt.kind != QuitEvent
  if doPoll:
      while pollEvent(evt):
          discard handleEvent(addr evt)
          if evt.kind == QuitEvent:
              break
  for w in app.windows:
    w.drawWindow()

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

