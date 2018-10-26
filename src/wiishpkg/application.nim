type
  App = object
    on_ready_procs: seq[proc()]

## The singleton application instance.
var app* = App()



when defined(macosx):
  when defined(ios):
    # iOS
    discard
  else:
    # macOS desktop
    discard
