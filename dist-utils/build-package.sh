#!/bin/bash

DISTRO=$(basename -- "$1")
if [[ -d "$2" && -w "$2" ]]
then DEST_DIR=$(realpath -- "$2")
else DEST_DIR=$PWD
fi

if [ -n "$3" ]; then
	BRANCH="$3"
else
	BRANCH=master
fi

DISTROS_DIR="$(realpath -- "$(dirname -- "$0")/../distros")"

usage() {
    printf "Usage: %s distro [output directory] [version]\n" "$0"
    printf "\ndistro\n\t\tThe name of the distribution to build a package for.\n"
    printf "\noutput directory\n\t\tThe directory where the package should be placed.\n"
    printf "\t\tIf omitted, the CWD is asumed as output directory.\n"
    printf "\nAvailable distros are:\n"
    ls -Qq1 "$DISTROS_DIR" | sed 's/^/ * /g'
    printf "\nThe version is git branch/tag\n"
    printf "\t You can see the available branches with git branch -r\n"
    printf "\t You can see the available tags with git tag -l\n"
    exit 1
}

if [[ -z "$DISTRO" || "${DISTRO:0:1}" = "." ]]
then usage
fi

cd "$DISTROS_DIR/$DISTRO" &> /dev/null || usage

source mkconfig.sh
docker run --privileged --rm -v "$DEST_DIR:/app" -t "$(docker build -q .)" sh -c "(su builduser -c \"./package.sh $BRANCH\") && $COPY_CMD"
