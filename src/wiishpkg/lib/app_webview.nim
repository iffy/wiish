## Webview Application
import macros
import times

import ./app_common
export app_common
import ../events

type
  WebviewApp* = ref object of BaseApplication
    windows*: seq[WebviewWindow]
  
  WebviewWindow* = ref object of BaseWindow

proc createApplication*(): WebviewApp =
  new(result)
  result.launched = newEventSource[bool]()
  result.willExit = newEventSource[bool]()
