#!/usr/bin/env bash

set -e

DEST_DIR="${1%/}"
FIX_DIR="${2%/}"

fix_lib () {
	LIB="$1"
	echo $LIB
	
	otool -L $LIB | tail -n +2 | awk '$1 ~ /^\/usr\/local.*\.dylib$/ {  print $1 }' | while IFS= read -r dep_path; do
		dep_name=$(basename "$dep_path")
		fix_path="$DEST_DIR/$dep_name"
		test -f $fix_path && continue
		install_name_tool -change "$dep_path" "$FIX_DIR/$dep_name" "$LIB"
		cp "$dep_path" "$fix_path"
		chmod +w $fix_path
		fix_lib $fix_path
	done
}

#ls $DEST_DIR/*.dylib | while IFS= read -r dylib; do fix_lib "$dylib"; done

echo $DEST_DIR
echo $FIX_DIR
