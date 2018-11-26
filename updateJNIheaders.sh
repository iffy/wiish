#!/bin/bash

set -e
THEDIR="wiishpkg/building/data/android-webview/app/src/main/java"
DST="../../../jni/src/mainjni.h"
RELPATH=$(python -c "import os,sys; print(os.path.relpath(sys.argv[1]))" "${THEDIR}/${DST}")
cd "$THEDIR"
javah -jni -o "$DST" org.wiish.exampleapp.WiishActivity
echo "Updated ${RELPATH}"
