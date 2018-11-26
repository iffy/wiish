## Hello, World Wiish App
import wiishpkg/webview_mobile
import os
import strformat
import strutils
import logging

let index_html = app.resourcePath("index.html").replace(" ", "%20")

app.launched.handle:
  debug "App launched"

app.willExit.handle:
  debug "App is exiting"

app.start(url = "file://" & index_html)

