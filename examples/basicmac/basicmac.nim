## Bare-bones MacOS application
# import strutils
# import sdl2
# import sdl2/gfx
# import system
# discard sdl2.init(INIT_EVERYTHING)

when defined(macosx):
  when defined(ios):
    # iOS
    echo "ios"
  else:
    # desktop macOS
    proc someNimFunc {.exportc.} =
      echo "some nim func"
    
    {.passL: "-framework Foundation" .}
    {.passL: "-framework AppKit" .}
    {.passL: "-framework ApplicationServices" .}
    
    {.compile: "stuff.m" .}
    
    type
      Id {.importc: "id", header: "<objc/Object.h>", final.} = distinct int
    
    proc newWiish: Id {.importobjc: "Wiish new", nodecl .}
    proc run(self: Id) {.importobjc: "run", nodecl .}
    proc windowID(self: Id):Id {.importobjc: "windowID", nodecl .}

    proc displayWindow() =
      var stuff:Id
      echo "displaying window"
      stuff = newWiish()
      stuff.run
      echo "after displaying window"

if isMainModule:
  displayWindow()