#!/bin/bash

# Script to build distro's package
# check the Dockerfile for any adittional dependencies
if [ -n "$1" ]; then
	export BRANCH=$1
fi

makepkg --clean --syncdeps --noconfirm
