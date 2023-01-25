## Hello, World Wiish App
import std/json
import std/logging
import std/strutils
import std/tables

import wiish/async
import wiish/mobileutil
import wiish/plugins/webview

#---------------------------------------------------
# App logic
#---------------------------------------------------
var counter = initCountTable[string]()
var senderFn: proc(x:string) = nil

proc attachSender*(fn: proc(x:string)) =
  senderFn = fn

proc receiveMessage*(msg: string) =
  let data = msg.parseJson
  let color = data["color"].getStr("")
  if color != "":
    counter.inc(color)
    debug color, " +1"
    let count = counter[color]
    if not senderFn.isNil:
      senderFn($ %* {"color": color, "count": count})

var timerCounter = 0
proc timerGuts =
  {.gcsafe.}:
    if not senderFn.isNil:
      timerCounter.inc()
      senderFn($ %* {"color": "timer", "count": timerCounter})

proc startTimer() =
  when useChronos:
    discard setTimer(Moment.fromNow(1.seconds),
      proc (arg: pointer) {.gcsafe, raises: [Defect].} =
        try:
          timerGuts()
        except:
          discard
        startTimer()
    )
  else:
    when not defined(android):
      addTimer(1000, false, proc(fd: AsyncFD):bool =
        timerGuts()
      )

startTimer()

#---------------------------------------------------
# Where wiish comes in...
#---------------------------------------------------
var app = newWebviewApp()
let index_html = "file://" & resourcePath("index.html").replace(" ", "%20")

app.life.addListener proc(ev: LifeEvent) =
  debug "event: ", $ev
  case ev.kind
  of AppStarted:
    debug "AppStarted"
    when wiish_mobile:
      debug "documents path: ", documentsPath()
  of WindowAdded:
    var win = app.getWindow(ev.windowId)
    win.onReady.handle:
      attachSender(proc(msg: string) =
        win.sendMessage(msg)
      )
    win.onMessage.handle(msg):
      receiveMessage(msg)
  else:
    debug "Unhandled lifecycle message: ", $ev

app.start(index_html, title = "Wiish Webview Demo")
