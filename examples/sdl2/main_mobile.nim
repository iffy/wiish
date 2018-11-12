## Hello, World Wiish App
import wiishpkg/mobile
import logging
import sdl2
import sdl2/gfx
import sdl2/ttf

debug "Pre launch..."

app.launched.handle:
  debug "App launched"
  # if not ttfInit():
  #   debug $getError()

  var w = app.newSDLWindow(title = "Hello, SDL Wiish!")
  var renderer = createRenderer(w.sdlWindow, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
  if renderer.isNil:
    destroy w.sdlWindow
    quit(1)
  
  # Open the font file
  # let fontsize = (32.0).cint
  # let fontfile = app.resourcePath("Lato-Regular.ttf")
  # debug "Trying to open font: ", fontfile.repr
  # let font:FontPtr = openFont(fontfile, fontsize)
  var rectangle = rect(50, 50, 50, 50)

  # Create the text
  # var textSurface:SurfacePtr = font.renderTextBlended("Hello, World!", color(50, 100, 50, 255))
  # var textRect = rect(20, 20, textSurface.w, textSurface.h)
  # var texture:TexturePtr = renderer.createTextureFromSurface(textSurface)
  # textSurface.freeSurface()

  # Perform drawing for the window.
  w.onDraw.handle(rect):
    debug "onDraw"
    # Draw background
    renderer.setDrawColor 255,255,255,255
    renderer.clear

    # Draw rectangle
    renderer.setDrawColor 0,0,255,255
    renderer.fillRect(rectangle.unsafeAddr)

    # Render the text
    # renderer.copy(texture, nil, textRect.unsafeAddr)

    # Make it so!
    renderer.present

app.willExit.handle:
  # Run this code just before the application exits
  debug "App is exiting"

app.start()


