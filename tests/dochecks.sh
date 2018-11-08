#!/bin/bash
RC=0

set -x
nim check --os:macosx examples/helloworld/main_desktop.nim || RC=1
nim check --os:macosx -d:ios --noMain examples/helloworld/main_mobile.nim || RC=1
nim check --os:windows examples/helloworld/main_desktop.nim || RC=1
nim check --os:linux examples/helloworld/main_desktop.nim || RC=1

exit $RC
