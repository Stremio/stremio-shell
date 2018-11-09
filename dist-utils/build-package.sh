#!/bin/bash

DISTRO=$1

usage() {
    echo Usage: $0 '<distro>'
    echo Available distros are:
    ls -Qq1 ../distros | sed 's/^/ * /g'
    exit 1
}

test -z "$DISTRO" && usage

DEST_DIR=$(pwd)
cd "../distros/$DISTRO" || usage
source mkconfig.sh
docker run --rm -v "$DEST_DIR:/app" -t "$(docker build -q .)" sh -c "$COPY_CMD"