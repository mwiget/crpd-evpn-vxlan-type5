#!/bin/sh
docker stop c1 c2 || true

docker run -ti -d --rm --name c1 --cap-add NET_ADMIN alpine
docker run -ti -d --rm --name c2 --cap-add NET_ADMIN alpine

echo "connect $1 with $2 with 2 links ..."
docker run -ti --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock --pid host marcelwiget/link-containers c1/c2
docker run -ti --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock --pid host marcelwiget/link-containers c1/c2/3000

docker ps

echo "show interfaces in container c1:"
docker exec -ti c1 ip link
