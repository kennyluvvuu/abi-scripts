#!/bin/sh

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

# P2P к R1 (lan4 — напрямую, без бриджа)
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
service network restart
