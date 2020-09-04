#!/bin/bash
FAILFILE="/tmp/failurefile"
OKFILE="/tmp/okfile"
[ -e "$FAILFILE" ] && rm "$FAILFILE"
[ -e "$OKFILE" ] && rm "$OKFILE"

nimcheck() {
  echo $*
  CMD="nim check --hints:off -d:testconcepts $*"
  if $CMD; then
    echo "$CMD" >> "$OKFILE"
  else
    echo "$CMD" >> "$FAILFILE"
  fi
}

macOS="--os:macosx"
linux="--os:linux"
windows="--os:windows"
ios="--os:macosx -d:ios --noMain"
android="--os:linux -d:android --noMain"
mobiledev="-d:wiish_mobiledev"

echo SDL tests
nimcheck $macOS examples/sdl2/main_desktop.nim
nimcheck $windows examples/sdl2/main_desktop.nim
nimcheck $linux examples/sdl2/main_desktop.nim

echo webview tests
nimcheck $macOS examples/webview/main_desktop.nim
nimcheck $windows examples/webview/main_desktop.nim
nimcheck $linux examples/webview/main_desktop.nim
nimcheck $android examples/webview/main_mobile.nim
nimcheck $ios examples/webview/main_mobile.nim
nimcheck $mobiledev examples/webview/main_mobile.nim

if [ -e "$OKFILE" ]; then
  echo ""
  echo "The following calls succeeded:"
  cat "$OKFILE"
fi
if [ -e "$FAILFILE" ]; then
  echo ""
  echo "The following calls failed:"
  cat "$FAILFILE"
  exit 1
fi
