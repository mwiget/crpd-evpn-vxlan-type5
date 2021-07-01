all: build run

build:
	docker build -t link-containers .

run:
	docker run -ti --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock --pid host --entrypoint /bin/ash link-containers
