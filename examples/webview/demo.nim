import tables
import logging
import json

var counter* = initCountTable[string]()
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
      echo "sending?"
      senderFn($ %* {"color": color, "count": count})
