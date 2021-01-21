## Hello, World Wiish App
import wiish/plugins/webview
import wiish/mobileutil
import strutils
import logging
import tables
import json
import asyncdispatch

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

when not defined(android):
  var timerCounter = 0
  addTimer(1000, false, proc(fd: AsyncFD):bool =
    {.gcsafe.}:
      timerCounter.inc()
      senderFn($ %* {"color": "timer", "count": timerCounter})
  )

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
