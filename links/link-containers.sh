#!/bin/sh
echo "connect $1 with $2 ..."
docker run -ti --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock --pid host link-containers $1 $2
