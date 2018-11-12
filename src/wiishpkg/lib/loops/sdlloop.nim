## This module provides functions for creating SDL windows
## A good chunk of this code is based heavily on
## https://github.com/yglukhov/nimx
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
     NimMain();
     return nim_program_result;
 }
 
""".}

macro passToCAndL(s: string): typed {.used.} =
  result = newNimNode(nnkStmtList)
  result.add parseStmt("{.passL: \"" & s.strVal & "\".}\n")
  result.add parseStmt("{.passC: \"" & s.strVal & "\".}\n")

macro useFrameworks(n: varargs[string]): typed {.used.} =
  result = newNimNode(nnkStmtList, n)
  for i in 0..n.len-1:
    result.add parseStmt("passToCAndL(\"-framework " & n[i].strVal & "\")")

when defined(ios):
  useFrameworks(
    "AudioToolbox",
    "AVFoundation",
    "CoreAudio",
    "CoreGraphics",
    "CoreMotion",
    "GameController",
    "Metal",
    "OpenGLES",
    "QuartzCore",
    "UIKit",
  )
elif defined(macosx):
  useFrameworks(
    "AudioToolbox",
    "CoreAudio",
    "CoreGraphics",
    "OpenGL",
    "AppKit",
    "AudioUnit",
    "ForceFeedback",
    "IOKit",
    "Carbon",
    "CoreServices",
    "ApplicationServices",
    "QuartzCore",
  )

proc initSDLIfNeeded() =
  var sdlInitialized {.global.} = false
  if not sdlInitialized:
    if sdl2.init(INIT_EVERYTHING) != SdlSuccess:
      echo "Error: sdl2.init(INIT_EVERYTHING): ", getError()
    sdlInitialized = true
    
    if glSetAttribute(SDL_GL_STENCIL_SIZE, 8) != 0:
      echo "Error: could not set stencil size: ", getError()

    when defined(ios) or defined(android):
      discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, 0x0004)
      discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2)

proc show*(w: Window) =
  w.sdlWindow.showWindow()
  w.sdlWindow.raiseWindow()

proc initGLWindow(w: Window, r: Rect)=
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

proc newGLWindow*(app: Application, title:string = ""): Window =
  initSDLIfNeeded()
  result.new()
  app.windows.add(result)
  result.initGLWindow(newRect(100, 200, 300, 400))
  result.sdlWindow.setTitle(title)
  result.show()

proc initSDLWindow(w: Window, r: Rect) =
  w.sdlWindow = createWindow(nil, cint(r.x), cint(r.y), cint(r.width), cint(r.height), SDL_WINDOW_RESIZABLE or SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_HIDDEN)
  if w.sdlWindow == nil:
    echo "Could not create window!"
    quit 1

proc newSDLWindow*(app: Application, title:string = ""): Window =
  initSDLIfNeeded()
  result.new()
  app.windows.add(result)
  result.initSDLWindow(newRect(150, 250, 300, 400))
  result.sdlWindow.setTitle(title)
  result.show()

proc drawWindow(w: Window) =
  if w.sdlGlContext != nil:
    # GL window
    discard glMakeCurrent(w.sdlWindow, w.sdlGlContext)
    glClearColor(45/255.0, 52/255.0, 54/255.0, 0)
    glClear(GL_COLOR_BUFFER_BIT)
    glFlush()
    w.onDraw.emit(newRect(0, 0, 0, 0))
    w.sdlWindow.glSwapWindow()
  else:
    # SDL window
    w.onDraw.emit(newRect(0, 0, 0, 0))

proc handleEvent(app: Application, event: ptr sdl2.Event): Bool32 =
  app.sdl_event.emit(event)
  result = True32

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

proc nextEvent(app: Application, evt: var sdl2.Event) =
  var was_event = false
  when defined(ios):
    proc iPhoneSetEventPump(enabled: Bool32) {.importc: "SDL_iPhoneSetEventPump".}
    iPhoneSetEventPump(True32)
    pumpEvents()
    iPhoneSetEventPump(False32)
    while pollEvent(evt):
      discard handleEvent(app, addr evt)
      was_event = true
  else:
    # var doPoll = false
    if waitEvent(evt):
      discard handleEvent(app, addr evt)
      was_event = true
      # doPoll = evt.kind != QuitEvent
    # if doPoll:
    #   while pollEvent(evt):
    #     discard handleEvent(app, addr evt)
    #     if evt.kind == QuitEvent:
    #       break
  
  if was_event:
    for w in app.windows:
      w.drawWindow()

template start*(app: Application) =
  sdlMain()
  var evt = sdl2.Event(kind: UserEvent1)
  app.launched.emit(true)
  while true:
    nextEvent(app, evt)
    if evt.kind == QuitEvent:
      break

  app.willExit.emit(true)
  discard quit(evt)

proc quit*(app: Application) =
  echo "NOT IMPLEMENTED"

