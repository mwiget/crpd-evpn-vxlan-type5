#!/usr/bin/env python3

import sys
import time
import os
import docker
from pyroute2 import NetNS, IPRoute


def create_netns(container):
    client = docker.from_env()
    if not (os.path.exists("/var/run/netns/" + container)):
        # print("path doesn't exists")
        while True:
            try:
                co = client.containers.get(container)
                if co.attrs['State']['Running']:
                    break

            except:
                print("waiting for container {} ...".format(container))
                sys.stdout.flush()
                time.sleep(1)
                pass

        pid = co.attrs['State']['Pid']
        # print("{} has pid={}".format(container, pid))
        os.symlink("/proc/{}/ns/net".format(pid),
                   "/var/run/netns/" + container)


def newifname(container):
    ns = NetNS(container)
    i = 1
    for link in ns.get_links():
        ifname = link.get_attr('IFLA_IFNAME')
        if ifname.startswith('net'):
            i += 1
    ns.close()
    return('net{}'.format(i))


def addlink(c1, c2, mtu):
    create_netns(c1)
    ifname1 = newifname(c1)
    create_netns(c2)
    ifname2 = newifname(c2)

    ipr = IPRoute()
    ipr.link('add', ifname='veth1', kind='veth', peer='veth2')
    idx1 = ipr.link_lookup(ifname='veth1')[0]
    idx2 = ipr.link_lookup(ifname='veth2')[0]
    ipr.link('set', index=idx1, ifname=ifname1,
             net_ns_fd=c1, state='up', mtu=mtu)
    ipr.link('set', index=idx2, ifname=ifname2,
             net_ns_fd=c2, state='up', mtu=mtu)
    print("link {}:{} <---> {}:{} with mut={} created".format(c1,
                                                              ifname1, c2, ifname2, mtu))


if __name__ == '__main__':
    if (len(sys.argv) < 2):
        print(
            "usage: {} container1/container2/[mtu] [...]".format(sys.argv[0]))
        exit(1)
    for arg in sys.argv:
        if arg == sys.argv[0]:
            continue
        mtu = 1500
        try:
            (c1, c2, mtu) = arg.split('/')
            mtu = int(mtu)
        except:
            (c1, c2) = arg.split('/')
        addlink(c1, c2, mtu)
