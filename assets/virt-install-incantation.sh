#!/bin/sh

# this is the incantation to get an ubuntu-18 virtual machine qcow
# up and started.  Move the qcow2 file to your favorite place.

virt-install \
  --name test \
  --ram=1024 \
  --vcpus=1 \
  --cpu host \
  --hvm \
  --disk path=./ubuntu18.qcow2,size=8 \
  --cdrom ubuntu-18.04.2-live-server-amd64.iso \
  --graphics vnc \
  --network network=default

# hit all the normal prompts and it will set itself up with DHCP as expected.
#
# you'll want to set up the following things:
#
# sudo brctl addbr dhcptest0
# sudo ip link set dev dhcptest0 up
# sudo ip addr add 192.168.122.1/24 dev dhcptest0