#!/bin/bash

set -e

until ip link show net1 up; do
  echo "waiting for net1 up ..."
  sleep 1
done

ip addr add 1.1.2.2/30 dev net1
ip -6 addr add abcd::1.1.2.2/126 dev net1

ip route add 1.1.0.0/16 via 1.1.2.1
ip -6 route add abcd::/48 via abcd::1.1.2.1

if [ -e /root/xdp_router.o ]; then
  mount -t bpf bpf /sys/fs/bpf/
  ulimit -l 2048
  /sbin/xdp_loader -d net1 --auto-mode --force --filename /root/xdp_router.o --progsec xdp_pass
  ethtool --offload net1 tx off
fi

tail -f /dev/null
