#!/bin/bash

set -e

if [ $# -ne 3 ]; then
	echo Usage: $0 App.app user pass
	exit 1
fi
APP_PATH="$1"
ZIP_PATH="$APP_PATH.zip"
USER="$2"
PASS="$3"

echo Compresing...
ditto -c -k --rsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo Sending notarizing request...
REQUEST=$(xcrun altool --notarize-app -t osx -f "$ZIP_PATH" --primary-bundle-id com.smartcodeltd.stremio -u "$USER" -p "$PASS" | awk '/RequestUUID =/ { print $3 }')

echo Got request ID: $REQUEST

rm "$ZIP_PATH"

#get_status() {
#	xcrun altool --notarization-info "$REQUEST" -u "$USER" -p "$PASS" | awk '/Status:/ { print $2 }'
#}
#
#echo Checking notarizing response...
#STATUS="$(get_status)" 
#while [ "$STATUS" == "in progress" ]; do
#	sleep 30
#	echo Not ready yet. Checking again...
#	STATUS="$(get_status)" 
#done
#
#echo Status: $STATUS
#
#if [ "$STATUS" != "success" ]; then
#	exit 1
#fi
echo Waiting for notarization...
sleep 480

echo Check the notarization status...
xcrun altool --notarization-info "$REQUEST" -u "$USER" -p "$PASS"

echo Stapling the app...
xcrun stapler staple "$APP_PATH"
echo Done.
