## Hello, World Wiish App
import wiishpkg/webview_mobile
import strformat
import strutils
import logging

info "Start"

let index_html = app.resourcePath("index.html").replace(" ", "%20")
info "index_html: " & index_html

app.launched.handle:
  debug "App launched"

app.willExit.handle:
  debug "App is exiting"

app.start(url = "file://" & index_html)

