#!/bin/bash

set -e
set -x # for debugging

DEST_DIR=./stremio.app/Contents/MacOS

cp ./mac/ffmpeg $DEST_DIR/
cp $(which node) $DEST_DIR/
chmod +w $DEST_DIR/ffmpeg
chmod +w $DEST_DIR/node

ls ./deps/libmpv/mac/lib/*.dylib
ls ./stremio.app/Contents/
ls ./stremio.app/Contents/Frameworks/

cp ./deps/libmpv/mac/lib/*.dylib ./stremio.app/Contents/Frameworks/

# https://bugreports.qt.io/browse/QTBUG-57265
# you don't want to be using always-overwrite in any version until Qt 5.11.3
macdeployqt ./stremio.app -executable=./stremio.app/Contents/MacOS/ffmpeg -executable=./stremio.app/Contents/MacOS/node

curl https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/$TAG/server.js > $DEST_DIR/server.js
# ./mac/fix_osx_deps.sh "./stremio.app/Contents/Frameworks" "@executable_path/../Frameworks"
