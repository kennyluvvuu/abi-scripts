#!/bin/sh

# Удаляем дефолтный lan бридж
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

# P2P к R2 (lan4 — напрямую, без бриджа)
uci set network.p2p=interface
uci set network.p2p.device=lan4
uci set network.p2p.proto=static
uci set network.p2p.ipaddr=10.10.10.1
uci set network.p2p.netmask=255.255.255.252

uci set system.@system[0].hostname=r1.au.team

uci commit network
uci commit system
service network restart
