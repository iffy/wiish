## Hello, World Wiish App
import wiishpkg/mobile
import logging
import sdl2/sdl
import sdl2/sdl_ttf as ttf

app.launched.handle:
  debug "App launched"
  discard ttf.init()

  var w = app.newSDLWindow(title = "Hello, SDL Wiish!")
  var renderer = createRenderer(w.sdlWindow, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
  if renderer.isNil:
    w.sdlWindow.destroyWindow()
    quit(1)
  
  # Open the font file
  let fontsize = (32.0).cint
  let fontfile = app.resourcePath("Lato-Regular.ttf")
  debug "Trying to open font: ", fontfile.repr
  let font = openFont(fontfile, fontsize)
  var rectangle = sdl.Rect(x: 50, y: 50, w: 50, h: 50)

  # Create the text
  var textSurface = font.renderTextBlended("Hello, World!", tupleToColor((50, 100, 50, 255)))
  var textRect = sdl.Rect(x: 20, y: 20, w: textSurface.w, h: textSurface.h)
  var texture = renderer.createTextureFromSurface(textSurface)
  textSurface.freeSurface()

  # Create the text
  # var textSurface:SurfacePtr = font.renderTextBlended("Hello, World!", color(50, 100, 50, 255))
  # var textRect = rect(20, 20, textSurface.w, textSurface.h)
  # var texture:TexturePtr = renderer.createTextureFromSurface(textSurface)
  # textSurface.freeSurface()

  # Perform drawing for the window.
  w.onDraw.handle(rect):
    debug "onDraw"
    # Draw background
    discard renderer.setRenderDrawColor(255,255,255,255)
    discard renderer.renderClear()

    # Draw rectangle
    discard renderer.setRenderDrawColor(0,0,255,255)
    discard renderer.renderFillRect(rectangle.unsafeaddr)

    # Render the text
    discard renderer.renderCopy(texture, nil, textRect.unsafeAddr)

    # Render the text
    # renderer.copy(texture, nil, textRect.unsafeAddr)

    # Make it so!
    renderer.renderPresent()

app.willExit.handle:
  # Run this code just before the application exits
  debug "App is exiting"

app.start()


