## Hello, World Wiish App
import wiishpkg/webview_mobile
import os
import strformat
import strutils
import logging
import times

let index_html = app.resourcePath("index.html").replace(" ", "%20")

app.launched.handle:
  debug "app: App launched"
  app.window.onMessage.handle(message):
    case message
    of "fs":
      let path = app.documentsPath()
      debug "got documents path: ", path
      let somefile = path/"atest.txt"
      if somefile.existsFile():
        debug "file already exists! ", somefile.extractFilename()
        debug "contents: ", somefile.readFile()
      writeFile(somefile, "Some contents")
      for item in path.walkDir(true):
        debug "item: ", $item
    else:
      debug "unknown command: " & message

app.willExit.handle:
  debug "app: App is exiting"

app.start(url = "file://" & index_html)
