#!/bin/bash

set -e

if [ $# -ne 4 ]; then
	echo Usage: $0 App.app user pass team_id
	exit 1
fi
APP_PATH="$1"
ZIP_PATH="$APP_PATH.zip"
USER="$2"
PASS="$3"
TEAM_ID="$4"

echo Compresing...
ditto -c -k --rsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Create keychain profile"
xcrun notarytool store-credentials "notarytool-profile" --apple-id "$USER" --team-id "$TEAM_ID" --password "$PASS"

echo Sending notarizing request...
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "notarytool-profile" --wait

rm "$ZIP_PATH"

echo Stapling the app...
xcrun stapler staple "$APP_PATH"
echo Done.
