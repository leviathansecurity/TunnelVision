#!/bin/bash

# Name of interface that is UP (bridged to your host) - you can set these manually if you want
external_interface=$(ifconfig | grep -oP 'enp0\S*' | sed 's/:$//' | head -n 1)

# Name of interface that is DOWN (the internal network we'll be acting as a DHCP server on) - you can set these manually if you want
internal_interface=$(ifconfig -a | grep -oP 'enp0\S*' | grep -v "^$(ifconfig | grep -oP 'enp0\S*' | head -n 1)$" | sed 's/:$//' | head -n 1)

echo "External Interface: $external_interface"
echo "Internal Interface: $internal_interface"

echo "Enabling internal interface..."
ifconfig $internal_interface up || { echo "Error enabling internal interface"; exit 1; }

echo "Configuring IP address..."
ip addr add 192.168.1.1/24 dev $internal_interface || { echo "Error configuring IP address"; exit 1; }

echo "Starting DHCP server..."
systemctl start isc-dhcp-server || { echo "Error starting DHCP server"; exit 1; }

echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 || { echo "Error enabling IP forwarding"; exit 1; }

echo "Configuring NAT rules..."
echo "iptables -t nat -A POSTROUTING -o $external_interface -j MASQUERADE"
iptables -t nat -A POSTROUTING -o $external_interface -j MASQUERADE || { echo "Error configuring NAT rule"; exit 1; }

echo "iptables -A FORWARD -i $internal_interface -o $external_interface -j ACCEPT"
iptables -A FORWARD -i $internal_interface -o $external_interface -j ACCEPT || { echo "Error configuring FORWARD rule"; exit 1; }

echo "iptables -A FORWARD -i $external_interface -o $internal_interface -m state --state ESTABLISHED,RELATED -j ACCEPT"
iptables -A FORWARD -i $external_interface -o $internal_interface -m state --state ESTABLISHED,RELATED -j ACCEPT || { echo "Error configuring FORWARD rule"; exit 1; }

echo "Startup script completed successfully."
