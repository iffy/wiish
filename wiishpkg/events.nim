## This module implements ``EventSource``, which lets you 
## register event handlers and then emit events.
runnableExamples:
  var
    es = newEventSource[string]()
    messages: seq[string]
    count: int
  es.handle(msg):
    messages.add(msg)
  es.handle:
    inc(count)
  es.emit("foo")
  es.emit("bar")
  doAssert messages == @["foo", "bar"]
  doAssert count == 2


import sequtils

type
  EventSource*[T] = object
    listeners: seq[proc(message:T):void]

proc newEventSource*[T](): EventSource[T] =
  result = EventSource[T]()

proc addListener*[T](es: var EventSource[T], listener: proc(message:T):void) =
  ## Add a proc to handle events.  Proc will be called once for each
  ## event emit.  See the ``handle`` template for a nicer syntax.
  es.listeners.add(listener)

proc removeListener*[T](es: var EventSource[T], listener: proc(message:T):void) =
  ## Remove a proc from receiving any more events.
  es.listeners.del(es.listeners.find(listener))

proc emit*[T](es: EventSource[T], message: T) =
  ## Emit an event to all event listeners
  for listener in es.listeners:
    listener(message)

template handle*[T](es: EventSource[T], varname:untyped, fnbody:untyped): untyped =
  ## Convient syntax for addListener
  runnableExamples:
    var es = newEventSource[string]()
    es.handle(thestring):
      echo "Got thestring: " & thestring
    es.emit("some string")

  es.addListener(proc(varname:T) =
    fnbody
  )

template handle*[T](es: EventSource[T], fnbody: untyped): untyped =
  ## Convient syntax for when you don't care about the event's message
  runnableExamples:
    var es = newEventSource[string]()
    es.handle:
      echo "Got a message"
    es.emit("some string")
  handle(es, _, fnbody)
