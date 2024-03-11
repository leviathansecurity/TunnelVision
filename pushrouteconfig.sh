#!/bin/bash
 
rm /etc/dhcp/dhcpd.conf
cp /etc/dhcp/dhcpd-route.conf /etc/dhcp/dhcpd.conf
systemctl restart isc-dhcp-server
systemctl status isc-dhcp-server