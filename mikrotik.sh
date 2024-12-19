#!/bin/bash
# MikroTik
IPNET="192.168.228.128"
MIKROTIK_IP="192.168.200.1"
MPORT="30005"
UBUNTU_IP="192.168.34.1"

expect << EOF > /dev/null
spawn telnet $IPNET $MPORT
expect "Mikrotik Login:"
send "admin\r"

expect "Password:"
send "\r"

expect ">"
send "n"

expect "new password"
send "123\r"

expect "repeat new password"
send "123\r"

expect ">"

# Menambahkan IP MikroTik pada ether2
send "/ip address add address=192.168.200.1/24 interface=ether2\r"

# Menambahkan DHCP client pada ether1
send "/ip dhcp-client add interface=ether1 disabled=no\r"

# Menambahkan DHCP Pool
send "/ip pool add name=dhcp_pool ranges=192.168.200.2-192.168.200.200\r"

# Menambahkan DHCP Server pada ether2
send "/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool\r"

# Menambahkan network untuk DHCP Server MikroTik
send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8\r"

# Mengaktifkan DHCP Server
send "/ip dhcp-server enable dhcp1\r"

# Menambahkan NAT untuk koneksi internet
send "/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade\r"

# Menambahkan route untuk komunikasi dengan Ubuntu
send "/ip route add dst-address=192.168.34.0/24 gateway=192.168.200.1\r"

# Menambahkan route untuk komunikasi dengan Cisco
send "/ip route add dst-address=192.168.228.128/32 gateway=192.168.200.1\r"

# Mengaktifkan IP forwarding
send "/ip settings set ip-forwarding=yes\r"

expect eof
EOF