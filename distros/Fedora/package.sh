#!/bin/bash

rpmdev-setuptree
spectool --get-files -R stremio.spec
rpmbuild -ba stremio.spec