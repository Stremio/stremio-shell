#!/bin/bash

docker run --rm -v "$(pwd):/app" -t "$(docker build -qf ./ArchLinux.dockerfile .)" sh -c 'cp *.pkg.tar.xz /app/'

