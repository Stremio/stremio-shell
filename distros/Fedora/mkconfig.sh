#!/bin/bash

TMPL_FILE=stremio.spec.tpl
DEST_FILE=stremio.spec
VERSION="$(git describe --long | sed 's/\([^-]*-\)g/r\1/;s/-/./g')"

sed '/^%description$/r../../dist-utils/common/description' "$TMPL_FILE" > "$DEST_FILE"
sed -i '/^%post$/r../../dist-utils/common/postinstall' "$DEST_FILE"
sed -i '/^test/r../../dist-utils/common/preremove' "$DEST_FILE"
sed -i '2,${/^#!/d}' "$DEST_FILE"
sed -i "s/PKG_VER/$VERSION/" "$DEST_FILE"

export COPY_CMD='cp rpmbuild/RPMS/*/*.rpm /app/'
