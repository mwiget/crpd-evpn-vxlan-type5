FROM alpine:3.13
RUN apk add py3-dockerpty py3-pyroute2

COPY add_link.py /
RUN chmod a+rx /add_link.py && mkdir /var/run/netns

ENTRYPOINT ["/usr/bin/python3", "/add_link.py"]
