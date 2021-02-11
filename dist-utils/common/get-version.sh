#!/usr/bin/env bash

cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 

sed -E '/^project\(/!d;s/^.*VERSION "([^"]+)".*$/\1/g' CMakeLists.txt
