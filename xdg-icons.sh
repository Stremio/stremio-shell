#!/bin/bash

mode="$1"
src="$2"
dst="$3"

case "$mode" in
	install)
		dst="$3"
		;;
	uninstall)
		dst="$2"
		;;
	*)
		echo "usage:"
		echo "usage: $0 install /path/to/image resource_name"
		echo "usage: $0 uninstall resource_name"
		exit 1
		;;
esac
for i in 16 22 24 32 64 128
do
	if [ "$mode" = "install" ]
	then
		convert -background none "$src" -resize $i "$dst.png"
		xdg-icon-resource "$mode" --context apps --size $i "$dst.png" "$dst"
		rm "$dst.png"
	else
		xdg-icon-resource "$mode" --context apps --size $i "$dst"
	fi
done
