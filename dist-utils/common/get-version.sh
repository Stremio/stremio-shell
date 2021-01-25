#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 

sed -E '/STREMIO_SHELL_VERSION=/!d;s/^.*STREMIO_SHELL_VERSION="([^"]+)".*$/\1/g' CMakeLists.txt
