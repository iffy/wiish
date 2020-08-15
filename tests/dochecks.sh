#!/bin/bash
FAILFILE="/tmp/failurefile"
[ -e "$FAILFILE" ] && rm "$FAILFILE"

nimcheck() {
  echo $*
  nim check --hints:off $* || echo "nim check $*" >> "$FAILFILE"
}

echo SDL tests
nimcheck --os:macosx examples/sdl2/main_desktop.nim
nimcheck --os:windows examples/sdl2/main_desktop.nim
nimcheck --os:linux examples/sdl2/main_desktop.nim

echo webview tests
nimcheck --os:macosx examples/webview/main_desktop.nim
nimcheck --os:windows examples/webview/main_desktop.nim
nimcheck --os:linux examples/webview/main_desktop.nim
nimcheck --os:linux -d:android --noMain examples/webview/main_mobile.nim
nimcheck --os:macosx -d:ios --noMain examples/webview/main_mobile.nim

if [ -e "$FAILFILE" ]; then
  echo "The following calls failed:"
  cat "$FAILFILE"
  exit 1
fi
