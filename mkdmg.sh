#!/usr/bin/env bash

set -e

source="$1"
title="$2"

tempDMGName="$TMPDIR/pack.temp.dmg"
finalDMGName="$title.dmg"

size=$(du -s Stremio/ | perl -MPOSIX -ne 'BEGIN { $c = 0 } { $c += ceil($_ * 512 / 1000 / 1000) } END { print ceil($c + 20) }')

hdiutil create -srcfolder "${source}" -volname "${title}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${size}m $tempDMGName

device=$(hdiutil attach -readwrite -noverify -noautoopen $tempDMGName | egrep '^/dev/' | sed 1q | awk '{print $1}')

SetFile -c icnC "/Volumes/$title/.VolumeIcon.icns"

echo device
read -r bgW bgH <<<$(file images/osx-inst.png  | perl -ne '/,\s*(\d+)\s*x\s*(\d+),/; print "$1 $2"')
echo '
   tell application "Finder"
     tell disk "'${title}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 400 + '${bgW}', 100 + '${bgH}'}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 120
           set background picture of theViewOptions to file ".background:osx-inst.png"
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "'${title}'" of container window to {142, 212}
           set position of item "Applications" of container window to {384, 212}
           close
           open
           update without registering applications
           delay 5
           close
     end tell
   end tell
' | osascript

chmod -Rf go-w /Volumes/"$title"
sync
hdiutil detach ${device}
hdiutil convert "$tempDMGName" -format UDZO -imagekey zlib-level=9 -o "$finalDMGName"

rm -f $tempDMGName

