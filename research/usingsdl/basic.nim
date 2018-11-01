## Bare-bones SDL2 example
import strutils
import sdl2, sdl2/gfx, sdl2/ttf, system

discard sdl2.init(INIT_EVERYTHING)

var
  window: WindowPtr
  render: RendererPtr

window = createWindow("SDL Skeleton", 100, 100, 640,480, SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE)

render = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
if render.isNil:
  destroy window
  quit(1)

# Make rectangle
var rect = rect(50, 50, 50, 50)
var velx:cint = 3
var vely:cint = 2

# Border
ttfInit()
var navbar = rect(0, 0, 100, 100)
let font = openFont("Inconsolata-Regular.ttf", 12)
let black = color(0, 0, 0, 50)
let message = font.renderTextSolid("some text", black)
var message_rect = rect(0,0,200,15)
let texture = createTextureFromSurface(render, message)
# let message_rect = rect(0, 0, 100, 100)
let another_rect = rect(0, 0, 100, 100)

var
  evt = sdl2.defaultEvent
  runGame = true
  fpsman: FpsManager
# fpsman.init


while runGame:
  while pollEvent(evt):
    if evt.kind == QuitEvent:
      runGame = false
      break
    elif evt.kind == WindowEvent:
      echo "window event ", repr(evt)


  let dt = fpsman.getFramerate() / 1000

  # Draw background
  render.setDrawColor 255,255,255,255
  render.clear

  # Draw rectangle
  render.setDrawColor 0,0,255,255
  render.fillRect(rect.unsafeAddr)
  
  # Draw a hard line
  render.drawLine(0, 100, 200, 300)

  # Draw aa line
  render.aalineRGBA(100, 100, 300, 400, 0, 0, 0, 255)
  render.aalineRGBA(50, 50, 250, 250, 255, 0, 0, 255)
  render.aacircleRGBA(200, 200, 50, 0, 255, 0, 127)
  render.filledCircleRGBA(200, 200, 50, 0, 255, 0, 127)
  render.arcRGBA(500, 200, 24, 12, 180, 0, 0, 0, 255)

  # Draw text
  render.setDrawBlendMode(BlendMode_Blend)
  
  # render.fillRect(another_rect.unsafeAddr)
  render.copy(texture, message_rect.unsafeAddr, nil)

  render.present
  rect.x += velx
  rect.y += vely
  if rect.x > (640 - 50) or rect.x < 0:
    velx *= -1
  if rect.y > (480 - 50) or rect.y < 0:
    vely *= -1
  fpsman.delay

destroy render
destroy window
