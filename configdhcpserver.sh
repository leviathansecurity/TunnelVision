#!/bin/bash

echo "Updating and upgrading packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

echo "Installing DHCP server and net-tools..."
sudo apt-get install isc-dhcp-server net-tools -y

echo "Creating /etc/dhcp/dhcpd-noroute.conf and /etc/dhcp/dhcpd-route.conf..."
# Create dhcpd-noroute.conf
touch /etc/dhcp/dhcpd-noroute.conf

# Add content to dhcpd-noroute.conf
printf "# dhcpd.conf\nauthoritative;\noption rfc3442  code 121 = array of integer 8;\noption ms-rfc3442 code 249 = array of integer 8;\n\n subnet 192.168.1.0 netmask 255.255.255.0 {\nrange 192.168.1.10 192.168.1.239;\noption domain-name-servers 8.8.8.8;\n option subnet-mask 255.255.255.0;\noption routers 192.168.1.1;\noption broadcast-address 192.168.1.255;\ndefault-lease-time 30;\nmax-lease-time 30;\n} " > /etc/dhcp/dhcpd-noroute.conf

# Create dhcpd-route.conf
touch /etc/dhcp/dhcpd-route.conf

# Add content to dhcpd-route.conf
printf "# dhcpd.conf\nauthoritative;\noption rfc3442  code 121 = array of integer 8;\noption ms-rfc3442 code 249 = array of integer 8;\n\n subnet 192.168.1.0 netmask 255.255.255.0 {\nrange 192.168.1.10 192.168.1.239;\noption domain-name-servers 8.8.8.8;\noption subnet-mask 255.255.255.0;\noption routers 192.168.1.1;\noption broadcast-address 192.168.1.255;\ndefault-lease-time 30;\nmax-lease-time 30;\noption rfc3442  32, 8, 8, 8, 8, 192, 168, 1, 1;\noption ms-rfc3442 32, 8, 8, 8, 8, 192, 168, 1, 1;\n} " > /etc/dhcp/dhcpd-route.conf

echo "Deleting and replacing /etc/dhcp/dhcpd.conf with no route push config..."
rm /etc/dhcp/dhcpd.conf
cp /etc/dhcp/dhcpd-noroute.conf /etc/dhcp/dhcpd.conf

echo "Configuration completed."
