#!/bin/bash

docker run --rm -v "$(pwd):/app" -t "$(docker build -qf ./Ubuntu.dockerfile .)" sh -c 'cp *.deb /app/'

