## An example of making an application that uses fonts.
## Based heavily on http://hg.libsdl.org/SDL_ttf/file/8c0d97042815/showfont.c
import strutils
import strformat
import os
import sdl2, sdl2/gfx, sdl2/ttf, system
discard sdl2.init(INIT_EVERYTHING)
ttfInit()

# Create the window
var window:WindowPtr = createWindow("SDL w/ Fonts", 100, 100, 640,480, SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE or SDL_WINDOW_ALLOW_HIGHDPI)
var display_index = window.getDisplayIndex()

# Set the scale factor based on DPI
var
  scale = 1.0
  ddpi, hdpi, vdpi: cfloat
if not getDisplayDPI(display_index, ddpi.addr, hdpi.addr, vdpi.addr):
  echo "Error getting display DPI"
echo "ddpi: ", ddpi
echo "hdpi: ", hdpi
echo "vdpi: ", vdpi
scale = hdpi / 50.0 # why is this 50 on my mac?
echo "scale: ", scale

# Open the font file
let fontsize = (16.0*scale).cint
let fontfile = "./Lato-Regular.ttf"
let font:FontPtr = openFont(fontfile, fontsize)
echo &"Loaded font: {fontfile}"

var renderer:RendererPtr = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
if renderer.isNil:
  destroy window
  quit(1)

# Create the text
var textSurface:SurfacePtr = font.renderTextBlended("Hello, World!", color(212, 215, 220, 255))
if textSurface.isNil:
  echo "Error: textSurface is nil!"
  quit(1)
var textRect:Rect = rect(20, 20, textSurface.w, textSurface.h)
var texture:TexturePtr = renderer.createTextureFromSurface(textSurface)
textSurface.freeSurface()

# Render the text
renderer.setDrawColor(43,62,81,255)
renderer.clear()
renderer.copy(texture, nil, textRect.unsafeAddr)
renderer.present()

var evt = sdl2.defaultEvent
var keepgoing = true

while keepgoing:
  while evt.pollEvent():
    if evt.kind == QuitEvent:
      keepgoing = false
      break

texture.destroyTexture()
font.close()
destroy renderer
destroy window
