#! /bin/bash

LOVE_ANDROID=../love-android-sdl2

cd src/
zip -r game.love * -x *.git*

mv game.love ${LOVE_ANDROID}/assets
cd $LOVE_ANDROID
ant debug
adb install -r ${LOVE_ANDROID}/bin/love_android_sdl2-debug.apk
