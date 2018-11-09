#!/bin/bash

TMPL_FILE=stremio.spec.tpl
DEST_FILE=stremio.spec
sed '/^%description$/r../../dist-utils/common/description' "$TMPL_FILE" > "$DEST_FILE"
sed -i '/^%post$/r../../dist-utils/common/postinstall' "$DEST_FILE"
sed -i '/^test/r../../dist-utils/common/preremove' "$DEST_FILE"
sed -i '2,${/^#!/d}' "$DEST_FILE"

export COPY_CMD='cp rpmbuild/RPMS/*/*.rpm /app/'