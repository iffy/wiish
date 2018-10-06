## An example of making an application that uses fonts.
## Based heavily on http://hg.libsdl.org/SDL_ttf/file/8c0d97042815/showfont.c
import strutils
import strformat
import os
import sdl2, sdl2/gfx, system
discard sdl2.init(INIT_EVERYTHING)

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

# Make a renderer
var renderer:RendererPtr = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
if renderer.isNil:
  destroy window
  quit(1)

# Clear the area
renderer.setDrawColor(0, 0, 0, 255)
renderer.clear()

# Make things blend
renderer.setDrawBlendMode(BlendMode_Blend)
# renderer.setDrawBlendMode(BlendMode_Add)
# renderer.setDrawBlendMode(BlendMode_Mod)
# renderer.setDrawBlendMode(BlendMode_None)

# Draw a rectangle
renderer.setDrawColor(0,0,255,255)
var r = rect(10, 10, 60, 60)
renderer.fillRect(r.unsafeAddr)

# Draw a circle
renderer.setDrawColor(0, 255, 0, 255)
renderer.filledCircleRGBA(70+10+25, 10+25, 25, 0, 255, 0, 255)

# Draw a line
renderer.aalineRGBA(10, 100, 60, 160, 255, 0, 0, 255)

# Show everything
renderer.present()

var evt = sdl2.defaultEvent
var keepgoing = true

while keepgoing:
  while evt.pollEvent():
    if evt.kind == QuitEvent:
      keepgoing = false
      break

destroy renderer
destroy window
