#!/bin/bash

# Script to build distro's package
# check the Dockerfile for any adittional dependencies
if [ -n "$1" ]; then
	export BRANCH=$1
fi
PKGEXT=".pkg.tar.xz"
makepkg --clean --syncdeps --noconfirm
