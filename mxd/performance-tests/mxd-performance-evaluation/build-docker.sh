#!/usr/bin/env sh

#todo provide your oun dockerID instead of PLACEHOLDER
docker build -t PLACEHOLDER/mxd-performance-test:0.3.5-SNAPSHOT .

docker image push PLACEHOLDER/mxd-performance-test:0.3.5-SNAPSHOT