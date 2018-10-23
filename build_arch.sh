#!/bin/bash

docker run --rm -v "$(pwd):/app" -t "$(docker build -qf ./ArchLinux.dockerfile .)" sh -c 'cp stremio-shell/*.pkg.tar.xz /app/'

