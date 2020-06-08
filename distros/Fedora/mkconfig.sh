#!/bin/bash

TMPL_FILE=stremio.spec.tpl
DEST_FILE=stremio.spec
if [[ -z "$BRANCH" ]]; then
    BRANCH=master
fi
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git stash
git checkout "$BRANCH"
VERSION="$(grep -oPm1 'VERSION=\K.+' ../../stremio.pro)"
git checkout "$CURRENT_BRANCH"
git stash pop

sed '/^%description$/r../../dist-utils/common/description' "$TMPL_FILE" > "$DEST_FILE"
sed -i '/^%post$/r../../dist-utils/common/postinstall' "$DEST_FILE"
sed -i '/^test/r../../dist-utils/common/preremove' "$DEST_FILE"
sed -i '2,${/^#!/d}' "$DEST_FILE"
sed -i "s/PKG_VER/$VERSION/" "$DEST_FILE"

export COPY_CMD='chmod 644 rpmbuild/RPMS/*/* && cp rpmbuild/RPMS/*/*.rpm /app/'
