#!/bin/bash

set -e

cp /etc/dhcp/dhcpd-route.conf /etc/dhcp/dhcpd.conf
systemctl restart isc-dhcp-server
systemctl status isc-dhcp-server