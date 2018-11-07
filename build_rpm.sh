#!/bin/bash

docker run --rm -v "$(pwd):/app" -t "$(docker build -qf ./Fedora.dockerfile .)" sh -c 'cp rpmbuild/RPMS/*/*.rpm /app/'

