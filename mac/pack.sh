#!/bin/bash

set -e

SHELL_VERSION=$(git grep -hoP '^\s*VERSION\s*=\s*\K.*$' HEAD -- stremio.pro)
DMG_PATH="Stremio $SHELL_VERSION.dmg"

mv ./stremio.app ./Stremio.app

ditto -c -k --rsrc --keepParent Stremio.app Stremio.app.zip
sed -ie 's/"title": "Stremio.*"/"title": "Stremio '$SHELL_VERSION'"/' ./mac/appdmg.json
appdmg ./mac/appdmg.json "$DMG_PATH"
