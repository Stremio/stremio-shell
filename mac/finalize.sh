#!/bin/bash

set -e

DEST_DIR=./stremio.app/Contents/MacOS

cp ./mac/ffmpeg $DEST_DIR/
cp $(which node) $DEST_DIR/
chmod +w $DEST_DIR/ffmpeg
chmod +w $DEST_DIR/node

macdeployqt ./stremio.app -always-overwrite -executable=./stremio.app/Contents/MacOS/ffmpeg -executable=./stremio.app/Contents/MacOS/node

curl https://s3-eu-west-1.amazonaws.com/stremio-artifacts/four/$TAG/server.js > $DEST_DIR/server.js
# ./mac/fix_osx_deps.sh "./stremio.app/Contents/Frameworks" "@executable_path/../Frameworks"
