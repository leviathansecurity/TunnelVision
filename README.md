# TunnelVision

This appears to work on any operating system that has a DHCP client that implements support for Option 121 rules. Notably, I tested it with success on Windows 10 and Ubuntu Desktop 22.04.03. When I tried it on a virtualized Android9.0 VM, I did not see any issue as Android (to this day as far as I can tell) does not support DHCP Option 121 classless static routes.

## **Under the following circumstances, a leak occurs:**
1. An attacker controls the DHCP server for the victim. This could be done by compromising a router on the same local network, an evil twin AP attack, a network administrator providing a configuration that accidentally leaks traffic for a VPN user, or by DHCPDISCOVERY packet racing a true DHCP server on the network. The race condition would only work on DHCP client implementations where it selects the first-lease offer when supplied multiple offers.
2. The attacker is also acting as the Gateway, so any traffic that is not encrypted by the VPN is readable to the attacker. As a DHCP server you configure the gateways of clients.
3. A user is using a VPN 
4. The user turns off any VPN client configuration setting that sets a host-firewall rule that drops traffic (if one exists) on the victim machine. 

If the option in #4 is turned on, this technique becomes a selective denial-of-service for arbitrary IP and ranges, as an attacker I can control these IP/ranges. This could lead a user to self-debug the problem and disable the setting, which would then leak the traffic.

## **How this is accomplished:**
- As the DHCP server for the victim, we supply a lease that is valid for a short amount of time. For the POC, I used 30-60 seconds. In some cases, windows doesn't like 2-10 second ranges and has mixed results.
- The VPN user connects to the VPN
- The attacker changes the DHCP configuration to push Option 121 classless static routes (RFC3442) to the victim. As an attacker, I can control the IP or ranges I want to leak by adjusting the prefix of the route I push. I.e. a /32 vs /1 prefix.
- The routing table of the victim adds the route from the DHCP automatically without the user’s consent or knowledge.
- Because the routing table makes routing decisions based on the prefix length, the highest prefix length match is chosen. I.e. a /32 route has a higher prefix length than a /1 route.
- If the chosen route, is one pushed by the DHCP server, it is automatically configured to go over a non-VPN interface. Therefore, since routing decisions happen before the traffic can be encrypted, it also is sent over a non-VPN interface to the default gateway without any encryption. Meaning, it does not matter what VPN protocol is in use or the strength of its encryption.
- Because the attacker sets themselves as the default gateway, they can then read that unencrypted traffic before forwarding it.
- Additionally, because the traffic is also forwarded by the gateway, the VPN tunnel remains connected, and the user would believe they are protected

To help illustrate the above attack path, I am including 3 diagrams I’ve made of data flow for the 3 scenarios.

### **Data flow for a VPN working normally without malicious DHCP routes**  
![Dataflow no leaks](images/Dataflow-VPN-connected-no-leaks.png)

### **Data flow for when an attacker is pushing 121 routes without a host-firewall setting enabled, creating a leak.**  
![Dataflow no leaks](images/Malicious-DHCP-route-successful-leak.png)

### **Data flow for when an attacker is pushing 121 routes and the creates a denial of service instead of a leak due to the host-firewall setting being enabled.**  
![Dataflow no leaks](images/DHCP-route-but-firewall-drops.png)

## **Steps to reproduce (virtualized lab, also can be configured on hardware with a switch):**
- Only tested on Windows based host for VirtualBox
- Download an Ubuntu 22.04.03 Server ISO; this will be our attacker DHCP server
- Use Virtualbox for emulation, create a VM, attach two network interfaces: one in bridged mode and one that is "internal network". Ideally, ensure your bridged network’s DHCP isn’t configured to hand out IPs in the range 192.168.1.0/24 as we will use be using that ourselves.
- Use the default installation options -- I recommend installing the openssh server so you can move the files there, but this can be accomplished via other means too.
- Log into the box after installation process.
- Start ssh service for file transfer:   `sudo systemctl start sshd.service`
- Find your ip address for the bridged adapter:   `hostname -I`
- From your host use an SSH client to transfer the files provided to the machine.
- Once the files are on the machine:   `chmod +x configdhcpserver.sh norouteconfig.sh pushrouteconfig.sh startup.sh`
- If you used WinSCP, such as I did, clean the files of their windows-ness so you can run them as an executable:   `for file in *; do [ -f "$file" ] && sed -i 's/\r$//' "$file"; done`
- Configure the server, choose default options if prompts come up:   `sudo ./configuredhcpserver.sh`
- Start the DHCP server with a non-malicious route (run this command from the VM, if ran from ssh it'll disconnect the session):  `sudo ./startup.sh`
- The server should now be configured to act as a gateway from the internal network to the bridged network. It also runs a DHCP server with a non-malicious configuration.
- Start an Ubuntu 22.04.03 Desktop VM or a Windows 10 VM in virtualbox -- this will be the victim machine. Choose internal network as its network adapter in the VMs settings.
- Install the VPN on the victim machine.
- Turn off any VPN setting that enables a host-firewall rule to drop traffic to non-VPN interfaces on the victim machine.
- Connect to the VPN server on the victim machine.
- On the attacker DHCP server, push the demo DHCP 121 route (8.8.8.8/32):        `sudo ./pushrouteconfig.sh` 
- On the victim machine, show the route table and observe there is a route for 8.8.8.8 that goes over a non-VPN interface: Ubuntu command:   `ip route`  Windows command:  `route print`
- Ping 8.8.8.8 from the victim machine to observe there is internet connectivity:   `ping 8.8.8.8`
- On the attacker DHCP server, observe you can read the unencrypted traffic:   `sudo tcpdump -i $interfacenamehere icmp`


**OPTIONAL:** Install Wireshark or tcpdump to the victim hosts and manually confirm the interface traffic flows over.

## **Virtual Machine**
There is a virtual machine image that will be easier to get up and running. 

**username:** administrator  
**password:** password
