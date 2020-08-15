## Hello, World Wiish App
import sdl2/sdl except log
import wiish/mobile
import logging
import opengl

import random
randomize()
var
  r = 45/255.0
  g = 52/255.0
  b = 54/255.0

app.launched.handle:
  # This is run as soon as the application is ready
  # to start making windows.
  debug "App launched"

  # Create a new window.
  var w = app.newGLWindow(title = "Hello, Wiish!")
  
  # Perform drawing for the window.
  w.onDraw.handle(rect):
    glClearColor(r, g, b, 0)
    glClear(GL_COLOR_BUFFER_BIT)

app.willExit.handle:
  # Run this code just before the application exits
  debug "App is exiting"

app.sdl_event.handle(evt):
  debug "Event"
  case evt.kind
  of MouseButtonDown:
    r = random(255).toFloat / 255.0
    g = random(255).toFloat / 255.0
    b = random(255).toFloat / 255.0
  else:
    discard

app.start()



# import os
# {.emit: """
# #ifndef SDL_MAIN_HANDLED
# #if defined(__WIN32__)
# /* On Windows SDL provides WinMain(), which parses the command line and passes
#   the arguments to your main function.

#   If you provide your own WinMain(), you may define SDL_MAIN_HANDLED
# */
# #define SDL_MAIN_AVAILABLE

# #elif defined(__WINRT__)
# /* On WinRT, SDL provides a main function that initializes CoreApplication,
#   creating an instance of IFrameworkView in the process.

#   Please note that #include'ing SDL_main.h is not enough to get a main()
#   function working.  In non-XAML apps, the file,
#   src/main/winrt/SDL_WinRT_main_NonXAML.cpp, or a copy of it, must be compiled
#   into the app itself.  In XAML apps, the function, SDL_WinRTRunApp must be
#   called, with a pointer to the Direct3D-hosted XAML control passed in.
# */
# #define SDL_MAIN_NEEDED

# #elif defined(__IPHONEOS__)
# /* On iOS SDL provides a main function that creates an application delegate
#   and starts the iOS application run loop.

#   See src/video/uikit/SDL_uikitappdelegate.m for more details.
# */
# #define SDL_MAIN_NEEDED

# #elif defined(__ANDROID__)
# /* On Android SDL provides a Java class in SDLActivity.java that is the
#   main activity entry point.

#   See README-android.txt for more details on extending that class.
# */
# #define SDL_MAIN_NEEDED

# #endif
# #endif /* SDL_MAIN_HANDLED */

# #ifdef __cplusplus
# #define C_LINKAGE   "C"
# #else
# #define C_LINKAGE
# #endif /* __cplusplus */

# /**
# *  \file SDL_main.h
# *
# *  The application's main() function must be called with C linkage,
# *  and should be declared like this:
# *  \code
# *  #ifdef __cplusplus
# *  extern "C"
# *  #endif
# *  int main(int argc, char *argv[])
# *  {
# *  }
# *  \endcode
# */
# #if defined(SDL_MAIN_NEEDED) || defined(SDL_MAIN_AVAILABLE)
# #define main    SDL_main
# #endif
# //#include <SDL2/SDL_main.h>
# extern int cmdCount;
# extern char** cmdLine;
# extern char** gEnv;
# N_CDECL(void, NimMain)(void);
# int main(int argc, char** args) {
#     cmdLine = args;
#     cmdCount = argc;
#     gEnv = NULL;
#     NimMain();
#     return nim_program_result;
# }
# """ .}

# proc foobar() {.exportc.} =
#   echo "foobar"

# while true:
#   echo "hello, world"
#   foobar()
#   os.sleep(1000)








# {.emit: """
# /*
#   Copyright (C) 1997-2018 Sam Lantinga <slouken@libsdl.org>

#   This software is provided 'as-is', without any express or implied
#   warranty.  In no event will the authors be held liable for any damages
#   arising from the use of this software.

#   Permission is granted to anyone to use this software for any purpose,
#   including commercial applications, and to alter it and redistribute it
#   freely.
# */
# #include <stdlib.h>
# #include <stdio.h>
# #include <string.h>
# #include <math.h>

# #include "SDL_test_common.h"

# #if defined(__IPHONEOS__) || defined(__ANDROID__)
# #define HAVE_OPENGLES
# #endif

# #ifdef HAVE_OPENGLES

# #include "SDL_opengles.h"

# static SDLTest_CommonState *state;
# static SDL_GLContext *context = NULL;
# static int depth = 16;

# /* Call this instead of exit(), so we can clean up SDL: atexit() is evil. */
# static void
# quit(int rc)
# {
#     int i;

#     if (context != NULL) {
#         for (i = 0; i < state->num_windows; i++) {
#             if (context[i]) {
#                 SDL_GL_DeleteContext(context[i]);
#             }
#         }

#         SDL_free(context);
#     }

#     SDLTest_CommonQuit(state);
#     exit(rc);
# }

# static void
# Render()
# {
#     static GLubyte color[8][4] = { {255, 0, 0, 0},
#     {255, 0, 0, 255},
#     {0, 255, 0, 255},
#     {0, 255, 0, 255},
#     {0, 255, 0, 255},
#     {255, 255, 255, 255},
#     {255, 0, 255, 255},
#     {0, 0, 255, 255}
#     };
#     static GLfloat cube[8][3] = { {0.5, 0.5, -0.5},
#     {0.5f, -0.5f, -0.5f},
#     {-0.5f, -0.5f, -0.5f},
#     {-0.5f, 0.5f, -0.5f},
#     {-0.5f, 0.5f, 0.5f},
#     {0.5f, 0.5f, 0.5f},
#     {0.5f, -0.5f, 0.5f},
#     {-0.5f, -0.5f, 0.5f}
#     };
#     static GLubyte indices[36] = { 0, 3, 4,
#         4, 5, 0,
#         0, 5, 6,
#         6, 1, 0,
#         6, 7, 2,
#         2, 1, 6,
#         7, 4, 3,
#         3, 2, 7,
#         5, 4, 7,
#         7, 6, 5,
#         2, 3, 1,
#         3, 0, 1
#     };


#     /* Do our drawing, too. */
#     glClearColor(0.0, 0.0, 0.0, 1.0);
#     glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

#     /* Draw the cube */
#     glColorPointer(4, GL_UNSIGNED_BYTE, 0, color);
#     glEnableClientState(GL_COLOR_ARRAY);
#     glVertexPointer(3, GL_FLOAT, 0, cube);
#     glEnableClientState(GL_VERTEX_ARRAY);
#     glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_BYTE, indices);

#     glMatrixMode(GL_MODELVIEW);
#     glRotatef(5.0, 1.0, 1.0, 1.0);
# }

# int
# main(int argc, char *argv[])
# {
#     int fsaa, accel;
#     int value;
#     int i, done;
#     SDL_DisplayMode mode;
#     SDL_Event event;
#     Uint32 then, now, frames;
#     int status;

#     /* Enable standard application logging */
#     SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

#     /* Initialize parameters */
#     fsaa = 0;
#     accel = 0;

#     /* Initialize test framework */
#     state = SDLTest_CommonCreateState(argv, SDL_INIT_VIDEO);
#     if (!state) {
#         return 1;
#     }
#     for (i = 1; i < argc;) {
#         int consumed;

#         consumed = SDLTest_CommonArg(state, i);
#         if (consumed == 0) {
#             if (SDL_strcasecmp(argv[i], "--fsaa") == 0) {
#                 ++fsaa;
#                 consumed = 1;
#             } else if (SDL_strcasecmp(argv[i], "--accel") == 0) {
#                 ++accel;
#                 consumed = 1;
#             } else if (SDL_strcasecmp(argv[i], "--zdepth") == 0) {
#                 i++;
#                 if (!argv[i]) {
#                     consumed = -1;
#                 } else {
#                     depth = SDL_atoi(argv[i]);
#                     consumed = 1;
#                 }
#             } else {
#                 consumed = -1;
#             }
#         }
#         if (consumed < 0) {
#             SDL_Log("Usage: %s %s [--fsaa] [--accel] [--zdepth %%d]\n", argv[0],
#                     SDLTest_CommonUsage(state));
#             quit(1);
#         }
#         i += consumed;
#     }

#     /* Set OpenGL parameters */
#     state->window_flags |= SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_BORDERLESS;
#     state->gl_red_size = 5;
#     state->gl_green_size = 5;
#     state->gl_blue_size = 5;
#     state->gl_depth_size = depth;
#     state->gl_major_version = 1;
#     state->gl_minor_version = 1;
#     state->gl_profile_mask = SDL_GL_CONTEXT_PROFILE_ES;
#     if (fsaa) {
#         state->gl_multisamplebuffers=1;
#         state->gl_multisamplesamples=fsaa;
#     }
#     if (accel) {
#         state->gl_accelerated=1;
#     }
#     if (!SDLTest_CommonInit(state)) {
#         quit(2);
#     }

#     context = (SDL_GLContext *)SDL_calloc(state->num_windows, sizeof(context));
#     if (context == NULL) {
#         SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Out of memory!\n");
#         quit(2);
#     }

#     /* Create OpenGL ES contexts */
#     for (i = 0; i < state->num_windows; i++) {
#         context[i] = SDL_GL_CreateContext(state->windows[i]);
#         if (!context[i]) {
#             SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_GL_CreateContext(): %s\n", SDL_GetError());
#             quit(2);
#         }
#     }

#     if (state->render_flags & SDL_RENDERER_PRESENTVSYNC) {
#         SDL_GL_SetSwapInterval(1);
#     } else {
#         SDL_GL_SetSwapInterval(0);
#     }

#     SDL_GetCurrentDisplayMode(0, &mode);
#     SDL_Log("Screen bpp: %d\n", SDL_BITSPERPIXEL(mode.format));
#     SDL_Log("\n");
#     SDL_Log("Vendor     : %s\n", glGetString(GL_VENDOR));
#     SDL_Log("Renderer   : %s\n", glGetString(GL_RENDERER));
#     SDL_Log("Version    : %s\n", glGetString(GL_VERSION));
#     SDL_Log("Extensions : %s\n", glGetString(GL_EXTENSIONS));
#     SDL_Log("\n");

#     status = SDL_GL_GetAttribute(SDL_GL_RED_SIZE, &value);
#     if (!status) {
#         SDL_Log("SDL_GL_RED_SIZE: requested %d, got %d\n", 5, value);
#     } else {
#         SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Failed to get SDL_GL_RED_SIZE: %s\n",
#                 SDL_GetError());
#     }
#     status = SDL_GL_GetAttribute(SDL_GL_GREEN_SIZE, &value);
#     if (!status) {
#         SDL_Log("SDL_GL_GREEN_SIZE: requested %d, got %d\n", 5, value);
#     } else {
#         SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Failed to get SDL_GL_GREEN_SIZE: %s\n",
#                 SDL_GetError());
#     }
#     status = SDL_GL_GetAttribute(SDL_GL_BLUE_SIZE, &value);
#     if (!status) {
#         SDL_Log("SDL_GL_BLUE_SIZE: requested %d, got %d\n", 5, value);
#     } else {
#         SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Failed to get SDL_GL_BLUE_SIZE: %s\n",
#                 SDL_GetError());
#     }
#     status = SDL_GL_GetAttribute(SDL_GL_DEPTH_SIZE, &value);
#     if (!status) {
#         SDL_Log("SDL_GL_DEPTH_SIZE: requested %d, got %d\n", depth, value);
#     } else {
#         SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Failed to get SDL_GL_DEPTH_SIZE: %s\n",
#                 SDL_GetError());
#     }
#     if (fsaa) {
#         status = SDL_GL_GetAttribute(SDL_GL_MULTISAMPLEBUFFERS, &value);
#         if (!status) {
#             SDL_Log("SDL_GL_MULTISAMPLEBUFFERS: requested 1, got %d\n", value);
#         } else {
#             SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Failed to get SDL_GL_MULTISAMPLEBUFFERS: %s\n",
#                     SDL_GetError());
#         }
#         status = SDL_GL_GetAttribute(SDL_GL_MULTISAMPLESAMPLES, &value);
#         if (!status) {
#             SDL_Log("SDL_GL_MULTISAMPLESAMPLES: requested %d, got %d\n", fsaa,
#                    value);
#         } else {
#             SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Failed to get SDL_GL_MULTISAMPLESAMPLES: %s\n",
#                     SDL_GetError());
#         }
#     }
#     if (accel) {
#         status = SDL_GL_GetAttribute(SDL_GL_ACCELERATED_VISUAL, &value);
#         if (!status) {
#             SDL_Log("SDL_GL_ACCELERATED_VISUAL: requested 1, got %d\n", value);
#         } else {
#             SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Failed to get SDL_GL_ACCELERATED_VISUAL: %s\n",
#                     SDL_GetError());
#         }
#     }

#     /* Set rendering settings for each context */
#     for (i = 0; i < state->num_windows; ++i) {
#         float aspectAdjust;

#         status = SDL_GL_MakeCurrent(state->windows[i], context[i]);
#         if (status) {
#             SDL_Log("SDL_GL_MakeCurrent(): %s\n", SDL_GetError());

#             /* Continue for next window */
#             continue;
#         }

#         aspectAdjust = (4.0f / 3.0f) / ((float)state->window_w / state->window_h);
#         glViewport(0, 0, state->window_w, state->window_h);
#         glMatrixMode(GL_PROJECTION);
#         glLoadIdentity();
#         glOrthof(-2.0, 2.0, -2.0 * aspectAdjust, 2.0 * aspectAdjust, -20.0, 20.0);
#         glMatrixMode(GL_MODELVIEW);
#         glLoadIdentity();
#         glEnable(GL_DEPTH_TEST);
#         glDepthFunc(GL_LESS);
#         glShadeModel(GL_SMOOTH);
#     }

#     /* Main render loop */
#     frames = 0;
#     then = SDL_GetTicks();
#     done = 0;
#     while (!done) {
#         /* Check for events */
#         ++frames;
#         while (SDL_PollEvent(&event)) {
#             switch (event.type) {
#             case SDL_WINDOWEVENT:
#                 switch (event.window.event) {
#                     case SDL_WINDOWEVENT_RESIZED:
#                         for (i = 0; i < state->num_windows; ++i) {
#                             if (event.window.windowID == SDL_GetWindowID(state->windows[i])) {
#                                 status = SDL_GL_MakeCurrent(state->windows[i], context[i]);
#                                 if (status) {
#                                     SDL_Log("SDL_GL_MakeCurrent(): %s\n", SDL_GetError());
#                                     break;
#                                 }
#                                 /* Change view port to the new window dimensions */
#                                 glViewport(0, 0, event.window.data1, event.window.data2);
#                                 /* Update window content */
#                                 Render();
#                                 SDL_GL_SwapWindow(state->windows[i]);
#                                 break;
#                             }
#                         }
#                         break;
#                 }
#             }
#             SDLTest_CommonEvent(state, &event, &done);
#         }
#         for (i = 0; i < state->num_windows; ++i) {
#             if (state->windows[i] == NULL)
#                 continue;
#             status = SDL_GL_MakeCurrent(state->windows[i], context[i]);
#             if (status) {
#                 SDL_Log("SDL_GL_MakeCurrent(): %s\n", SDL_GetError());

#                 /* Continue for next window */
#                 continue;
#             }
#             Render();
#             SDL_GL_SwapWindow(state->windows[i]);
#         }
#     }

#     /* Print out some timing information */
#     now = SDL_GetTicks();
#     if (now > then) {
#         SDL_Log("%2.2f frames per second\n",
#                ((double) frames * 1000) / (now - then));
#     }
# #if !defined(__ANDROID__)
#     quit(0);
# #endif        
#     return 0;
# }

# #else /* HAVE_OPENGLES */

# int
# main(int argc, char *argv[])
# {
#     SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "No OpenGL ES support on this system\n");
#     return 1;
# }

# #endif /* HAVE_OPENGLES */

# /* vi: set ts=4 sw=4 expandtab: */

# """.}