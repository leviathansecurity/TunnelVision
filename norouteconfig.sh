#!/bin/bash
 
rm /etc/dhcp/dhcpd.conf
cp /etc/dhcp/dhcpd-noroute.conf /etc/dhcp/dhcpd.conf
systemctl restart isc-dhcp-server
systemctl status isc-dhcp-server