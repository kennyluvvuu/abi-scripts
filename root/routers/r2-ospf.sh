#!/bin/sh
opkg update
opkg install frr frr-watchfrr frr-ospfd frr-staticd frr-zebra frr-vtysh

sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons

cat > /etc/frr/frr.conf << 'EOF'
frr version 8
frr defaults traditional
hostname r2.au.team

router ospf
 ospf router-id 2.2.2.2
 network 172.16.120.0/24 area 0
 network 172.16.100.0/24 area 0
 network 10.10.10.0/30 area 0

line vty
EOF

service frr enable
service frr start
