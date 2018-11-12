## Hello, World Wiish App
import wiishpkg/mobile
import sdl2, sdl2/gfx

app.launched.handle:
  log "App launched"
  var w = app.newSDLWindow(title = "Hello, SDL Wiish!")
  var renderer = createRenderer(w.sdlWindow, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
  if renderer.isNil:
    destroy w.sdlWindow
    quit(1)
  
  var rectangle = rect(50, 50, 50, 50)

  # Perform drawing for the window.
  w.onDraw.handle(rect):
    log "onDraw"
    # Draw background
    renderer.setDrawColor 255,255,255,255
    renderer.clear

    # Draw rectangle
    renderer.setDrawColor 0,0,255,255
    renderer.fillRect(rectangle.unsafeAddr)

    # Make it so!
    renderer.present

app.willExit.handle:
  # Run this code just before the application exits
  log "App is exiting"

app.start()


