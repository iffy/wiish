#!/bin/bash
RC=0

set -x
nim check --os:macosx examples/sdl2/main_desktop.nim || RC=1
nim check --os:macosx -d:ios --noMain examples/sdl2/main_mobile.nim || RC=1
nim check --os:windows examples/sdl2/main_desktop.nim || RC=1
nim check --os:linux examples/sdl2/main_desktop.nim || RC=1

exit $RC
