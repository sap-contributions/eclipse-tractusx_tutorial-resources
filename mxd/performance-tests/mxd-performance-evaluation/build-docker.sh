#!/usr/bin/env sh

docker build -t ciprian2398/mxd-performance-test:0.2.0-SNAPSHOT .

docker image push ciprian2398/mxd-performance-test:0.2.0-SNAPSHOT