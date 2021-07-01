#!/bin/bash

SECONDS=0
set -e

echo "checking for installed cRPD licenses ..."
for r in r1 r2; do
  license=$(docker-compose exec $r cli show system license | grep SKU)
  echo $r $license 
  if [ -z "$license" ]; then
    echo "missing crpd license !!"
    exit 1
  fi
done
echo ""

while true; do
  docker-compose exec -T r1 cli show isis adj | grep Up | wc -l | grep ^2$ >/dev/null && break
  echo "$SECONDS: waiting for all isis neighbors to be Up ..."
  sleep 5
done
echo "r1> cli show isis adj ..."
docker-compose exec -T r1 cli show isis adj

echo ""
while true; do
  docker-compose exec -T r1 cli show bgp summary | grep Establ | wc -l | grep ^1$ >/dev/null && break
  echo "$SECONDS: waiting for established BGP session ..."
  sleep 5
done
echo "r1> cli show bgp summary..."
docker-compose exec -T r1 cli show bgp summary

echo ""
for r in r1 r2; do
  while true; do
    docker-compose exec -T $r cli show evpn l3-context | grep VXLAN | wc -l | grep ^2$ >/dev/null && break
    echo "$SECONDS: waiting for evpn vxlan l3-context ..."
    sleep 5
  done
  echo "$r> cli show evpn l3-context ..."
  docker-compose exec -T $r cli show evpn l3-context
  echo ""
done

echo "r1> cli show evpn ip-prefix-database"
docker-compose exec -T r1 cli show evpn ip-prefix-database

echo ""
for r in r1 r2; do
  for vrf in vrf1 vrf2; do
    while true; do
      docker-compose exec -T $r ip route show vrf __crpd-$vrf | grep encap | wc -l | grep ^1$ >/dev/null && break
      echo "$SECONDS: waiting for ip route show vrf __crpd-$vrf (looking for encap route entry) ..."
      echo "execute 'restart routing immediately' on $r if encap route is missing"
      sleep 5
    done
    echo "$r:/# ip route show vrf __crpd-$vrf ..."
    docker-compose exec -T $r ip route show vrf __crpd-$vrf
    echo ""
  done
done

echo ""
for r in r1 r2; do
  for vrf in vrf1 vrf2; do
    while true; do
      docker-compose exec -T $r ip -6 route show vrf __crpd-$vrf | grep encap | wc -l | grep ^1$ >/dev/null && break
      echo "$SECONDS: waiting for ip -6 route show vrf __crpd-$vrf (looking for encap route entry) ..."
      echo "execute 'restart routing immediately' on $r if encap route is missing"
      sleep 5
    done
    echo "$r:/# ip -6 route show vrf __crpd-$vrf ..."
    docker-compose exec -T $r ip -6 route show vrf __crpd-$vrf
    echo ""
  done
done

docker-compose exec -T r1 tcpdump -i net1 -e -c 4 -s 1500 -w r1net1.pcap udp port 4789 &

echo "ipv4 connectivity test between c1 and c2 ..."
while true; do
  docker-compose exec -T c1 ping -fc 3 1.1.2.2 && break
  echo "$SECONDS: waiting to reach 1.1.2.2 ..."
  sleep 1
done

echo ""
echo "ipv4 connectivity test between c2 and c3 ..."
while true; do
  docker-compose exec -T c3 ping -fc 3 1.1.2.2 && break
  echo "$SECONDS: waiting to reach 1.1.2.2 ..."
  sleep 1
done

sleep 1
echo "tcpdump of vxlan traffic between r1 and r2 ..."
docker-compose exec -T r1 tcpdump -n -r r1net1.pcap -e || true

# TODO ipv6 connectivity not yet working ...
#echo "ipv6 connectivity test between c1 and c2 ..."
#while true; do
#  docker-compose exec -T c1 ping -fc 3 abcd::1.1.2.2 && break
#  echo "$SECONDS: waiting to reach abcd::1.1.2.2 ..."
#  sleep 1
#done

#echo "ipv6 connectivity test between c3 and c4 ..."
#while true; do
#  docker-compose exec -T c3 ping -fc 3 abcd::1.1.2.2 && break
#  echo "$SECONDS: waiting to reach abcd::1.1.2.2 ..."
#  sleep 1
#done

echo ""
echo "running iperf3 test between c1 and c2 for 10 seconds ..."
docker-compose exec -T c2 iperf3 -s &
sleep 2
docker-compose exec -T c1 iperf3 -c 1.1.2.2

echo ""
echo "success in $SECONDS seconds"
