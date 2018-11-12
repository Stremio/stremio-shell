#!/bin/bash

DISTRO=$(basename -- "$1")
DEST_DIR=$PWD
DISTROS_DIR="$(realpath "$(dirname -- "$0")/../distros")"

usage() {
    printf "Usage: %s <distro>\n\nAvailable distros are:\n" $0
    ls -Qq1 "$DISTROS_DIR" | sed 's/^/ * /g'
    exit 1
}

if [[ -z "$DISTRO" || "${DISTRO:0:1}" = "." ]]
then usage
fi

cd "$DISTROS_DIR/$DISTRO" &> /dev/null || usage

source mkconfig.sh
docker run --rm -v "$DEST_DIR:/app" -t "$(docker build -q .)" sh -c "$COPY_CMD"