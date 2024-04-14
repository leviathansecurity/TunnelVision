#!/bin/bash

set -e

cp /etc/dhcp/dhcpd-noroute.conf /etc/dhcp/dhcpd.conf
systemctl restart isc-dhcp-server
systemctl status isc-dhcp-server