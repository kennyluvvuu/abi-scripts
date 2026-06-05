#!/bin/bash

# Узнать имя интерфейса заранее через: ip addr show
IFACE=ens33  # заменить на своё

hostnamectl set-hostname srv.au.team

# Отключаем интерфейс
ip link set $IFACE down

# Статический IP
echo "172.16.110.50/24" > /etc/net/ifaces/$IFACE/ipv4address

# Маршрут по умолчанию
echo "default via 172.16.110.254" > /etc/net/ifaces/$IFACE/ipv4route

# Меняем DHCP на static
sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/' /etc/net/ifaces/$IFACE/options

# DNS
echo "nameserver 172.16.110.254" > /etc/resolv.conf

# Запись в /etc/hosts
echo "172.16.110.50  srv.au.team srv" >> /etc/hosts

service network restart
