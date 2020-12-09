#!/bin/bash

if [ -z "$ANDROID_HOME" ]; then
    echo "Set ANDROID_HOME to the Android SDK path (the sdk/ directory)"
    exit 1
fi

set -e
ANDROID_JAR="${ANDROID_HOME}/platforms/android-29/android.jar"
THEDIR="android-webview/app/src/main/java"
DST="../../../jni/src/"
RELPATH=$(python -c "import os,sys; print(os.path.relpath(sys.argv[1]))" "${THEDIR}/${DST}")
cd "$THEDIR"

javac -h "$DST" -cp "${ANDROID_JAR}:." -verbose org/wiish/exampleapp/WiishActivity.java
echo "Updated ${RELPATH}"
