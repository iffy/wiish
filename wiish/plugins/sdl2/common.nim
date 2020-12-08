## A good chunk of this code is based heavily on
## https://github.com/yglukhov/nimx

import sdl2
import opengl
import macros
import tables

type
  SDL2Window* = ref object
    sdlWindow*: sdl2.WindowPtr
    sdlGLContext*: sdl2.GlContextPtr
    draw*: proc(rect: Rectangle)

  Rectangle* = tuple
    x: float32
    y: float32
    w: float32
    h: float32

proc rect*(x, y, w, h: int = 0): Rectangle =
  ## Create a new rectangle
  (x.float32, y.float32, w.float32, h.float32)

proc show(win: SDL2Window) =
  win.sdlWindow.showWindow()
  win.sdlWindow.raiseWindow()

proc newSDLWindow*[T](app: T, title = "Wiish"): SDL2Window =
  ## Create a new SDL window
  new(result)
  let id = app.nextWindowId
  app.nextWindowId.inc()
  app.windows[id] = result
  result.sdlWindow = createWindow(nil, 150, 250, 300, 400, SDL_WINDOW_RESIZABLE or SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_HIDDEN)
  if result.sdlWindow.isNil:
    raise ValueError.newException("Failed to create SDL window!")
  result.sdlWindow.setTitle(title)
  result.show()

proc newGLWindow*[T](app: T, title = "Wiish"): SDL2Window =
  ## Create a new SDL window with OpenGL turned on
  new(result)
  let id = app.nextWindowId
  app.nextWindowId.inc()
  app.windows[id] = result
  result.sdlWindow = createWindow(nil, 150, 250, 300, 400, SDL_WINDOW_OPENGL or SDL_WINDOW_RESIZABLE or SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_HIDDEN)
  if result.sdlWindow == nil:
    raise ValueError.newException("Could not create window!")

  discard glSetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1)
  result.sdlGlContext = result.sdlWindow.glCreateContext()
  when not defined(ios) and not defined(android):
    loadExtensions()
  if result.sdlGlContext == nil:
    raise ValueError.newException("Could not create OpenGL Context!")
  discard glMakeCurrent(result.sdlWindow, result.sdlGlContext)
  glClearColor(45/255.0, 52/255.0, 54/255.0, 0)
  glClear(GL_COLOR_BUFFER_BIT)
  result.sdlWindow.setTitle(title)
  result.show()

proc redrawWindow*(win: SDL2Window) =
  if win.sdlGlContext != nil:
    # GL window
    discard glMakeCurrent(win.sdlWindow, win.sdlGlContext)
    glClearColor(45/255.0, 52/255.0, 54/255.0, 0)
    glClear(GL_COLOR_BUFFER_BIT)
    glFlush()
    if not win.draw.isNil:
      win.draw(rect(0, 0, 0, 0))
    win.sdlWindow.glSwapWindow()
  else:
    # SDL window
    if not win.draw.isNil:
      win.draw(rect(0, 0, 0, 0))

proc nextEvent*[T](app: T, evt: var Event) =
  ## Get the next SDL event
  var was_event = false
  if waitEvent(evt):
    app.sdlEvent.emit(evt)
    was_event = true
  
  if was_event:
    for win in app.windows.values:
      win.redrawWindow()

template sdlMain*() =
  when defined(ios) or defined(android):
    when defined(ios):
      {.emit: "#define __IPHONEOS__" .}
    when defined(android):
      {.emit: "#define __ANDROID__" .}

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

macro passToCAndL*(s: string): untyped {.used.} =
  result = newNimNode(nnkStmtList)
  result.add parseStmt("{.passL: \"" & s.strVal & "\".}\n")
  result.add parseStmt("{.passC: \"" & s.strVal & "\".}\n")

macro useFrameworks*(n: varargs[string]): untyped {.used.} =
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
