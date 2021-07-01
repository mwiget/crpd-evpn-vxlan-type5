#!/bin/bash

echo "checking for installed cRPD licenses ..."
for r in r1 r2; do
  license=$(docker-compose exec $r cli show system license | grep SKU)
  if [ -z "$license" ]; then
    if [ ! -e junos_sfnt.lic ]; then
      echo "please download your free eval license key from https://www.juniper.net/us/en/dm/crpd-free-trial.html"
      echo "(login required) and rename it to junos_sfnt.lic or add an existing license into the file directly into"
      echo "r1/junos.conf and r2/junos.conf"
    fi
    echo "adding license key junos_sfnt.lic to $r ..."
    cp junos_sfnt.lic $r/
    docker-compose exec $r cli request system license add /config/junos_sfnt.lic
  else
    echo "$r $license"
  fi
done
echo ""
