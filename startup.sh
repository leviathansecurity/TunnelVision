#!/bin/bash

set -e

# Name of interface that is UP (bridged to your host) - you can set these manually if you want
external_interface=$(ifconfig | grep -oP 'enp0[^:\s]*' | head -n 1)

# Name of interface that is DOWN (the internal network we'll be acting as a DHCP server on) - you can set these manually if you want
internal_interface=$(ifconfig -a | grep -oP 'enp0[^:\s]*' | grep -v "^$external_interface$" | head -n 1)

echo "External Interface: $external_interface"
echo "Internal Interface: $internal_interface"

echo "Enabling internal interface..."
ifconfig $internal_interface up

echo "Configuring IP address 10.13.37.1/24 on $internal_interface..."
ip addr add 10.13.37.1/24 dev $internal_interface

echo "Starting DHCP server..."
systemctl start isc-dhcp-server

echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1

echo "Configuring NAT rules..."
echo "iptables -t nat -A POSTROUTING -o $external_interface -j MASQUERADE"
iptables -t nat -A POSTROUTING -o $external_interface -j MASQUERADE

echo "iptables -A FORWARD -i $internal_interface -o $external_interface -j ACCEPT"
iptables -A FORWARD -i $internal_interface -o $external_interface -j ACCEPT

echo "iptables -A FORWARD -i $external_interface -o $internal_interface -m state --state ESTABLISHED,RELATED -j ACCEPT"
iptables -A FORWARD -i $external_interface -o $internal_interface -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "Startup script completed successfully."
