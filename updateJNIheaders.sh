#!/bin/bash

cd wiishpkg/building/data/android-webview/app/src/main/java
javah -jni -o ../../../jni/src/mainjni.h org.wiish.exampleapp.WiishActivity
