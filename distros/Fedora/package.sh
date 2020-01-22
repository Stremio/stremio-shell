#!/bin/bash
if [ -n "$1" ]; then
	export BRANCH="$1"
fi

rpmdev-setuptree
spectool --get-files -R stremio.spec
rpmbuild -ba stremio.spec
