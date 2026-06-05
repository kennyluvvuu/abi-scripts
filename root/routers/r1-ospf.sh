#!/bin/sh
# Установка пакетов
opkg update
opkg install frr frr-watchfrr frr-ospfd frr-staticd frr-zebra frr-vtysh

# Включить ospfd демон
sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons

# Конфиг OSPF для R1
cat > /etc/frr/frr.conf << 'EOF'
frr version 8
frr defaults traditional
hostname r1.au.team

interface lo
 ip address 1.1.1.1/32

router ospf
 ospf router-id 1.1.1.1
 network 172.16.10.0/24 area 0
 network 172.16.110.0/24 area 0
 network 10.10.10.0/30 area 0

line vty
EOF

service frr enable
service frr start
