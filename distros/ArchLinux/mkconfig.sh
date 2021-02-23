#!/bin/bash

TMPL_FILE=stremio.install.tpl
DEST_FILE=stremio.install
cp "$TMPL_FILE" "$DEST_FILE"
sed -i '/^post_install/r../../dist-utils/common/postinstall' "$DEST_FILE"
sed -i '/^pre_remove/r../../dist-utils/common/preremove' "$DEST_FILE"
sed -i '2,${/^#!/d}' "$DEST_FILE"

export COPY_CMD='cp *.pkg.tar.zst /app/'
export CLEAN_CMD="rm $DEST_FILE"
