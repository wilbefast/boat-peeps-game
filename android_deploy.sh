#! /bin/bash

LOVE_ANDROID=../love-android-sdl2

cd src/
rm -f game.love
zip -r game.love * -x *.git*
cd ../
rm -f ${LOVE_ANDROID}/assets/game.love
mv src/game.love ${LOVE_ANDROID}/assets
cd $LOVE_ANDROID
ant debug install