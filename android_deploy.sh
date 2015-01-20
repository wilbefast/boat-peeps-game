#! /bin/bash

LOVE_ANDROID=../love-android-sdl2

cd src/
zip -r game.love * -x *.git*
cd ../
mv game.love ${LOVE_ANDROID}/assets
cd $LOVE_ANDROID
ant debug install