#!/bin/bash

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo "I’m sorry, `getopt --test` failed in this environment."
    exit 1
fi

OPTIONS=d:t:
LONGOPTS=dest-dir:,tag:

# -use ! and PIPESTATUS to get exit code with errexit set
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

DISTROS_DIR="$(realpath -- "$(dirname -- "$0")/../distros")"
DEST_DIR=$PWD
BRANCH=master

while true; do
    case "$1" in
        -t|--tag)
            BRANCH="$2"
            shift 2
            ;;
        -d|--dest-dir)
            DEST_DIR=$(realpath -- "$2")
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

usage() {
    printf "Usage:\n %s [options] distro\n" "$0"
    printf "\ndistro\tThe name of the distribution to build a package for.\n"
    printf "\nOptions:\n"
    printf "\n -d, --dest-dir\t\tThe directory where the package should be placed.\n"
    printf "\t\t\tIf omitted, the CWD is asumed as output directory.\n"
    printf "\n -t, --tag\t\tThe git tag/branch to build against.\n"
    printf "\t\t\tBy default the build is against the master branch.\n"
    printf "\t\t\tYou can see the available tags with 'git tag -l'\n"
    printf "\t\t\tYou can see the available branches with 'git branch -r'\n"
    printf "\nAvailable distros are:\n"
    ls -Qq1 "$DISTROS_DIR" | sed 's/^/ * /g'
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

# This is not reliable
# if ! (git branch -r | sed 's/^[^/]*\///'; git tag -l) | grep -w "$BRANCH" > /dev/null; then
#     printf 'Invalid tag "%s"\n\n' "$BRANCH"
#     usage
# fi

DISTRO=$(basename -- "$1")

if [[ -z "$DISTRO" || "${DISTRO:0:1}" = "." ]]; then
    printf 'Invalid distro "%s"\n\n' "$DISTRO"
    usage
fi

if ! [[ -d "$DEST_DIR" && -w "$DEST_DIR" ]]; then
    printf 'Can not write to "%s". Check filesystem permissions\n\n' "$DEST_DIR"
    usage
fi

if ! cd "$DISTROS_DIR/$DISTRO" &> /dev/null; then
    printf 'Can not use distro "%s". Check filesystem permissions\n\n' "$DISTRO"
    usage
fi

source mkconfig.sh
IMAGE_HASH=$(docker build  . | tee >(cat >&2) | tail -n 1 | cut -d " " -f 3)
docker run --privileged --rm -v "$DEST_DIR:/app" -t "$IMAGE_HASH" sh -c "(su builduser -c \"./package.sh $BRANCH\") && $COPY_CMD"
