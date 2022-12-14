## Hello, World Wiish App
import wiish/plugins/sdl2/mobile
import logging
import sdl2
import sdl2/ttf

discard init(INIT_EVERYTHING)
discard ttfInit()

var app = newSDL2MobileApp()

app.life.addListener proc(ev: LifeEvent) =
  case ev.kind
  of AppStarted:
    debug "App launched"
    var w = app.newSDLWindow("Hello, Wiish!")
    #------------------------------------------------------
    # SDL-specific code
    #------------------------------------------------------
    var renderer = createRenderer(w.sdl_window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
    if renderer.isNil:
      w.sdl_window.destroyWindow()
      quit(1)
    
    # Open the font file
    let fontsize = (32.0).cint
    let fontfile = resourcePath("NotoSans-Regular.ttf")
    let font = openFont(fontfile, fontsize)
    var rectangle:Rect = (x: 50.cint, y: 50.cint, w: 50.cint, h: 50.cint)

    # Create the text
    var textSurface = font.renderUtf8Blended("Hello, мир!", color(50, 100, 50, 255))
    var textRect:Rect = (x: 20.cint, y: 20.cint, w: textSurface.w.cint, h: textSurface.h.cint)
    var texture = renderer.createTextureFromSurface(textSurface)
    textSurface.freeSurface()

    # Perform drawing for the window.
    w.draw = proc(rect: Rectangle) =
      # Draw background
      discard renderer.setDrawColor(255,255,255,255)
      discard renderer.clear()

      # Draw rectangle
      discard renderer.setDrawColor(0,0,255,255)
      discard renderer.fillRect(rectangle)

      # Render the text
      discard renderer.copy(texture, nil, textRect.addr)

      # Make it so!
      renderer.present()
  of AppWillExit:
    debug "App about to exit"
  else:
    debug "Lifecycle event: ", $ev.kind

app.start()
