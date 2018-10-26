import unittest
import wiishpkg/events

suite "events":
  
  test "single listener":
    var es = newEventSource[string]()
    var emitted:string
    es.addListener(proc(message:string) =
      emitted.add(message)
    )
    es.emit("hi")
    check emitted == "hi"
  
  test "remove listener":
    var es = newEventSource[string]()
    var emitted:string
    proc eventListener(message:string) =
      emitted.add(message)
    es.addListener(eventListener)
    es.emit("first")
    es.removeListener(eventListener)
    es.emit("second")
    check emitted == "first"
  
  test "multiple listeners":
    var es = newEventSource[string]()
    var emitted:string

    es.addListener(proc(message:string) =
      emitted.add("first")
      emitted.add(message)
    )
    es.addListener(proc(message:string) =
      emitted.add("second")
      emitted.add(message)
    )
    es.emit("hey")
    check emitted == "firstheysecondhey"

  test "nicer syntax":
    var es = newEventSource[string]()
    var emitted:string

    es.handle(message):
      emitted.add(message)
    
    es.emit("yup")
    check emitted == "yup"
