#!/bin/bash

set -e

TAG=${1:-master}

DEST_DIR=./stremio.app/Contents/MacOS

cp ./mac/ffmpeg $DEST_DIR/
cp ./mac/ffprobe $DEST_DIR/
cp $(which node) $DEST_DIR/
chmod +w $DEST_DIR/ffmpeg
chmod +w $DEST_DIR/ffprobe
chmod +w $DEST_DIR/node

mkdir -p ./stremio.app/Contents/Frameworks
cp ./deps/libmpv/mac/lib/*.dylib ./stremio.app/Contents/Frameworks/

# https://bugreports.qt.io/browse/QTBUG-57265
# you don't want to be using always-overwrite in any version until Qt 5.11.3
macdeployqt ./stremio.app -executable=./stremio.app/Contents/MacOS/ffmpeg -executable=./stremio.app/Contents/MacOS/ffprobe -executable=./stremio.app/Contents/MacOS/node

SHELL_VERSION=$(git grep -hoP '^\s*VERSION\s*=\s*\K.*$' HEAD -- stremio.pro)
curl $(cat ./server-url.txt) > $DEST_DIR/server.js
# ./mac/fix_osx_deps.sh "./stremio.app/Contents/Frameworks" "@executable_path/../Frameworks"
