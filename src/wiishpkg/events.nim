import sequtils

type
  EventSource*[T] = object
    listeners: seq[proc(message:T):void]

proc newEventSource*[T](): EventSource[T] =
  result = EventSource[T]()

proc addListener*[T](es: var EventSource[T], listener: proc(message:T):void) =
  es.listeners.add(listener)

proc removeListener*[T](es: var EventSource[T], listener: proc(message:T):void) =
  es.listeners.del(es.listeners.find(listener))

proc emit*[T](es: EventSource[T], message: T) =
  ## Emit an event to all event listeners
  for listener in es.listeners:
    listener(message)

template handle*[T](es: EventSource[T], varname:untyped, fnbody:untyped): untyped =
  ## Convient syntax for addListener
  es.addListener(proc(varname:T) =
    fnbody
  )
