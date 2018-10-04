#!/bin/bash

docker run -t "$(docker build -qf ./Ubuntu.dockerfile .)" sh -c 'tar c *.deb | cat' | tar x
