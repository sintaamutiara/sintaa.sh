#!/bin/bash

IPNET="192.168.228.128"
SPORT="30002"
MIKROTIK_IP="192.168.200.1"  # IP MikroTik
UBUNTU_IP="192.168.34.1"     # IP Ubuntu

# Menyambung ke Cisco dan mengkonfigurasi interface
{
    sleep 1
    echo "enable"
    sleep 1
    echo "configure terminal"
    sleep 1
    echo "int e0/1"
    sleep 1
    echo "sw mo acc"  # Mengubah mode interface menjadi akses
    sleep 1
    echo "sw acc vl 34"  # Mengonfigurasi VLAN 34 pada interface
    sleep 1
    echo "no sh"  # Mengaktifkan interface
    sleep 1
    echo "exit"
    sleep 1
    echo "interface e0/0"
    sleep 1
    echo "sw tr encap do"  # Mengonfigurasi trunk interface dengan mode dot1q
    sleep 1
    echo "sw mo tr"  # Mengubah mode interface menjadi trunk
    sleep 1
    echo "no sh"  # Mengaktifkan interface
    sleep 1
    echo "exit"
    sleep 1
    echo "ip route 192.168.200.0 255.255.255.0 $MIKROTIK_IP"  # Menambahkan route ke MikroTik
    sleep 1
    echo "ip route 192.168.34.0 255.255.255.0 $UBUNTU_IP"  # Menambahkan route ke Ubuntu
    sleep 1
} | telnet $IPNET $SPORT > /dev/null

# Memeriksa status konfigurasi
sleep 2
if [ $? -eq 0 ]; then
    echo "Konfigurasi CISCO berhasil diterapkan."
else
    echo "Terjadi kesalahan saat menerapkan konfigurasi."
fi