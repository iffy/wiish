const
  asyncBackend* {.strdefine.} = "chronos"
  useChronos* = asyncBackend == "chronos"
  useAsyncdispatch* = not useChronos

when useChronos:
  import chronos; export chronos
else:
  import std/asyncdispatch; export asyncdispatch

proc drainEventLoop*(timeout = 500) =
  ## Run the event loop until there's nothing left or the timeout
  ## is reached.
  when useChronos:
    let idlefut = idleAsync()
    try:
      waitFor wait(idlefut, timeout.milliseconds)
    except TimeoutError:
      discard
  else:
    drain(timeout)

