#!/bin/sh

# --- СЕТЬ ---

uci del network.@device[0]

# CAM-сеть (lan1, lan2)
uci set network.cam_dev=device
uci set network.cam_dev.name=br-cam
uci set network.cam_dev.type=bridge
uci add_list network.cam_dev.ports=lan1
uci add_list network.cam_dev.ports=lan2

uci set network.cam=interface
uci set network.cam.device=br-cam
uci set network.cam.proto=static
uci set network.cam.ipaddr=172.16.10.1
uci set network.cam.netmask=255.255.255.0

# SRV-сеть (lan3)
uci set network.srv_dev=device
uci set network.srv_dev.name=br-srv
uci set network.srv_dev.type=bridge
uci add_list network.srv_dev.ports=lan3

uci set network.srv=interface
uci set network.srv.device=br-srv
uci set network.srv.proto=static
uci set network.srv.ipaddr=172.16.110.254
uci set network.srv.netmask=255.255.255.0

# P2P к R2 (lan4)
uci set network.p2p=interface
uci set network.p2p.device=lan4
uci set network.p2p.proto=static
uci set network.p2p.ipaddr=10.10.10.1
uci set network.p2p.netmask=255.255.255.252

uci set system.@system[0].hostname=r1.au.team

uci commit network
uci commit system

# --- FIREWALL ---

# Удаляем дефолтную lan зону (индекс 1, wan обычно 0)
uci delete firewall.@zone[1]

# Зона CAMS
uci add firewall zone
uci set firewall.@zone[-1].name=CAMS
uci set firewall.@zone[-1].input=REJECT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=REJECT
uci add_list firewall.@zone[-1].network=cam

# Зона SERVERS
uci add firewall zone
uci set firewall.@zone[-1].name=SERVERS
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT
uci add_list firewall.@zone[-1].network=srv

# Зона TUNNELS
uci add firewall zone
uci set firewall.@zone[-1].name=TUNNELS
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT
uci add_list firewall.@zone[-1].network=p2p

# Форвардинг SERVERS <-> TUNNELS
uci add firewall forwarding
uci set firewall.@forwarding[-1].src=SERVERS
uci set firewall.@forwarding[-1].dest=TUNNELS

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=TUNNELS
uci set firewall.@forwarding[-1].dest=SERVERS

# Форвардинг SERVERS -> WAN
uci add firewall forwarding
uci set firewall.@forwarding[-1].src=SERVERS
uci set firewall.@forwarding[-1].dest=wan

# Форвардинг CAMS -> SERVERS (только камеры видят SRV)
uci add firewall forwarding
uci set firewall.@forwarding[-1].src=CAMS
uci set firewall.@forwarding[-1].dest=SERVERS

# NAT для SERVERS
uci add firewall redirect
uci set firewall.@redirect[-1].name=masq-servers
uci set firewall.@redirect[-1].src=SERVERS
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
hostname r1.au.team

router ospf
 ospf router-id 1.1.1.1
 network 172.16.10.0/24 area 0
 network 172.16.110.0/24 area 0
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
