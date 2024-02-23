#!/usr/bin/env bash

set -e

if test -n "$1"; then
	source="$1"/images
else
	source=images
fi

target=icons

mkdir -p "$target"

for size in 16 22 24 32 64 128; do
	rsvg-convert "$source"/stremio.svg -w "$size" \
		-o "$target"/smartcode-stremio_"$size".png
	rsvg-convert "$source"/stremio_tray_white.svg -w "$size" \
		-o "$target"/smartcode-stremio-tray_"$size".png
done
