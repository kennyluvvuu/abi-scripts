#!/bin/sh

# --- СЕТЬ ---

uci del network.@device[0]

# ADMIN-PC (lan1)
uci set network.admin_dev=device
uci set network.admin_dev.name=br-admin
uci set network.admin_dev.type=bridge
uci add_list network.admin_dev.ports=lan1

uci set network.admin=interface
uci set network.admin.device=br-admin
uci set network.admin.proto=static
uci set network.admin.ipaddr=172.16.120.1
uci set network.admin.netmask=255.255.255.0

# PRINT (lan2)
uci set network.print_dev=device
uci set network.print_dev.name=br-print
uci set network.print_dev.type=bridge
uci add_list network.print_dev.ports=lan2

uci set network.print=interface
uci set network.print.device=br-print
uci set network.print.proto=static
uci set network.print.ipaddr=172.16.100.1
uci set network.print.netmask=255.255.255.0

# P2P к R1 (lan4)
uci set network.p2p=interface
uci set network.p2p.device=lan4
uci set network.p2p.proto=static
uci set network.p2p.ipaddr=10.10.10.2
uci set network.p2p.netmask=255.255.255.252

# DHCP для ADMIN-PC
uci set dhcp.admin_pool=dhcp
uci set dhcp.admin_pool.interface=admin
uci set dhcp.admin_pool.start=10
uci set dhcp.admin_pool.limit=191
uci set dhcp.admin_pool.leasetime=12h
uci add_list dhcp.admin_pool.dhcp_option="119,au-team.abi"
uci add_list dhcp.admin_pool.dhcp_option="6,172.16.120.1"

# DHCP на print — отключить
uci set dhcp.print_pool=dhcp
uci set dhcp.print_pool.interface=print
uci set dhcp.print_pool.ignore=1

uci set system.@system[0].hostname=r2.au.team

uci commit network
uci commit dhcp
uci commit system

# --- FIREWALL ---

uci delete firewall.@zone[1]

# Зона ADMINS
uci add firewall zone
uci set firewall.@zone[-1].name=ADMINS
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT
uci add_list firewall.@zone[-1].network=admin

# Зона PRINTERS
uci add firewall zone
uci set firewall.@zone[-1].name=PRINTERS
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT
uci add_list firewall.@zone[-1].network=print

# Зона TUNNELS
uci add firewall zone
uci set firewall.@zone[-1].name=TUNNELS
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT
uci add_list firewall.@zone[-1].network=p2p

# Форвардинг ADMINS -> WAN
uci add firewall forwarding
uci set firewall.@forwarding[-1].src=ADMINS
uci set firewall.@forwarding[-1].dest=wan

# Форвардинг TUNNELS <-> ADMINS
uci add firewall forwarding
uci set firewall.@forwarding[-1].src=TUNNELS
uci set firewall.@forwarding[-1].dest=ADMINS

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=ADMINS
uci set firewall.@forwarding[-1].dest=TUNNELS

# Форвардинг TUNNELS <-> PRINTERS
uci add firewall forwarding
uci set firewall.@forwarding[-1].src=TUNNELS
uci set firewall.@forwarding[-1].dest=PRINTERS

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=PRINTERS
uci set firewall.@forwarding[-1].dest=TUNNELS

# NAT для ADMINS
uci add firewall redirect
uci set firewall.@redirect[-1].name=masq-admins
uci set firewall.@redirect[-1].src=ADMINS
uci set firewall.@redirect[-1].dest=wan
uci set firewall.@redirect[-1].target=MASQUERADE

uci commit firewall

# --- OSPF (FRR) ---

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
 no default-information originate
 area 0 authentication message-digest

interface lan4
 ip ospf message-digest-key 1 md5 abi2026
 ip ospf authentication message-digest

line vty
EOF

# --- ПРИМЕНЯЕМ ---

service network restart
service firewall restart
service frr enable
service frr start
