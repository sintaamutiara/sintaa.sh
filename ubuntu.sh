#bin sh!
#!/bin/bash

# Kode warna untuk umpan balik
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

#Variabel Konfigurasi
VLAN_INTERFACE="eth1.34"
VLAN_ID=34
IP_ADDR="$IP_Router$IP_Pref"      # IP address untuk interface VLAN di Ubuntu

# Destinasi folder
DHCP_CONF="/etc/dhcp/dhcpd.conf" #Tempat Konfigurasi DHCP
NETPLAN_CONF="/etc/netplan/01-netcfg.yaml" # Tempat Konfigurasi Netplan
DDHCP_CONF="/etc/default/isc-dhcp-server" #Tempat konfigurasi default DHCP
SYSCTL_CONF="/etc/sysctl.conf" #Tempat Konfigurasi IP Forwarding

#Ip PNETLAB
IPNET="192.168.228.128"
#ip default perangkat
IPU="192.168.34.1"
IPROUTE_ADD="192.168.200.1/24"
#MIKROTIK
MIKROTIK_IP="192.168.200.1"     # IP MikroTik yang baru
MIKROTIK_S="192.168.200.0"
MPORT="30005"
#CISCO
SPORT="30002"

#Konfigurasi IP Yang Anda Inginkan
IP_A="34"
IP_B="200"
IP_C="2"
IP_BC="255.255.255.0"
IP_Subnet="192.168.$IP_A.0"
IP_Router="192.168.$IP_A.1"
IP_Range="192.168.$IP_A.$IP_C 192.168.$IP_A.$IP_B"
IP_DNS="8.8.8.8, 8.8.4.4"
IP_Pref="/24"

# FIX DHCP
IP_FIX="192.168.34.10"
IP_MAC="00:50:79:66:68:03"

# Fungsi untuk memeriksa status exit
check_status() {
    local custom_message="$1"  # Menyimpan parameter pertama yang diberikan
    if [ $? -ne 0 ]; then
        # Jika perintah gagal
        if [ -z "$custom_message" ]; then  # Jika tidak ada pesan kustom, gunakan pesan default
            custom_message="terakhir"
        fi
        echo -e "${RED}❌ Terjadi kesalahan ketika ${custom_message}!${RESET}"
        exit 1
        sleep 3
    else
        # Jika perintah berhasil
        if [ -z "$custom_message" ]; then
            custom_message="terakhir"
        fi
        echo -e "${GREEN}✅ Perintah ${custom_message} berhasil dijalankan!${RESET}"
        sleep 3
    fi
}

check_akhir() {
if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Terjadi kesalahan pada OTOMASI, Cobalah Lagi!${RESET}"
  exit 1
else
  echo -e "${GREEN}✅ OTOMASI Telah Berhasil Dilakukan!${RESET}"        
fi
}
set -e

# Menampilkan pesan awal
clear
cat << EOF
   ____ _______ ____  __  __           _____ _____ _   _ _______       
  / __ \__   __/ __ \|  \/  |   /\    / ____|_   _| \ | |__   __|/\    
 | |  | | | | | |  | | \  / |  /  \  | (___   | | |  \| |  | |  /  \   
 | |  | | | | | |  | | |\/| | / /\ \  \___ \  | | | . ` |  | | / /\ \  
 | |__| | | | | |__| | |  | |/ ____ \ ____) |_| |_| |\  |  | |/ ____ \ 
  \____/  |_|  \____/|_|  |_/_/    \_\_____/|_____|_| \_|  |_/_/    \_\
EOF
sleep 5
echo "Inisialisasi awal ..."

# Menambahkan repositori Kartolo
echo "Menambahkan repositori Kartolo..."
cat <<EOF | sudo tee /etc/apt/sources.list > /dev/null 
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse 
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

# Cek keberhasilan menambahkan repositori
check_status "Menambahkan Repositori"

# Update dan instal paket yang diperlukan
echo "Mengupdate daftar paket dan menginstal paket yang diperlukan..."
sudo apt-get update -y > /dev/null #APTU
check_status "Update Repositori"

sudo apt-get install -y isc-dhcp-server expect > /dev/null #ISC expect
check_status "Menginstall Package Yang Diperlukan"


# Konfigurasi Pada Netplan
echo "Mengonfigurasi Netplan..."
cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1:
      dhcp4: no
  vlans:
     eth1.34:
       id: 34
       link: eth1
       addresses: [$IP_Router$IP_Pref]
EOF

# Cek keberhasilan konfigurasi Netplan
check_status "Konfigurasi Netplan"

# Terapkan konfigurasi Netplan
echo "Menerapkan konfigurasi Netplan..."
sudo netplan apply
check_status "Menerapkan Netplan"


# Mengkonfigurasi DHCP SERVER
echo "Menerapkan konfigurasi isc-dhcp-server..."
cat <<EOL | sudo tee $DHCP_CONF > /dev/null
# Konfigurasi subnet untuk VLAN 23
subnet $IP_Subnet netmask $IP_BC {
    range $IP_Range;
    option routers $IP_Router;
    option subnet-mask $IP_BC;
    option domain-name-servers $IP_DNS;
    default-lease-time 600;
    max-lease-time 7200;
}
# Konfigurasi Fix DHCP *OPTIONAL
host fantasia {
  hardware ethernet $IP_MAC;
  fixed-address $IP_FIX;
}
EOL
cat <<EOL | sudo tee $DDHCP_CONF > /dev/null
INTERFACESv4="$VLAN_INTERFACE"
EOL
check_status "Konfigurasi isc-dhcp-service"


# Mengaktifkan IP forwarding dan inisialisasi IPTables
echo "Mengaktifkan IP forwarding dan mengonfigurasi IPTables..."
sudo sysctl -w netpv4.ip_forward=1 > /dev/null
echo "net.ipv4.ip_forward=1" | sudo tee -a $SYSCTL_CONF > /dev/null
check_status "IP Forwarding"
# Konfigurasi Firewall
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE > /dev/null
sudo iptables -A OUTPUT -p tcp --dport $SPORT -j ACCEPT > /dev/null
sudo iptables -A OUTPUT -p tcp --dport $MPORT -j ACCEPT > /dev/null
sudo ufw allow $SPORT/tcp > /dev/null
sudo ufw allow $MPORT/tcp > /dev/null
sudo ufw allow from $IPNET to any port $SPORT > /dev/null
sudo ufw allow from $IPNET to any port $MPORT > /dev/null
sudo ufw reload > /dev/null
check_status "Konfigurasi Firewall"
# iptables-persistent
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent > /dev/null
check_status "Instalisasi iptables-Persistent"
sudo netfilter-persistent save > /dev/null


# Masuk Ke Sistem Cisco
echo "Melakukan Konfigurasi Untuk Cisco..."
./cisco.sh
check_status "Konfigurasi Cisco"

# Masuk Ke Sistem Mikrotik
echo "Melakukan Konfigurasi Untuk Mikrotik..."
./mik.sh
check_status "Konfigurasi Mikrotik"

# Routing Ubuntu dan Mikrotik
echo "Melakukan Routing Ubuntu Ke Mikrotik..."
sudo ip route add 192.168.200.0/24 via 192.168.34.2
check_status "Routing Ubuntu dan Mikrotik"

# MeRestart Sistem isc-dhcp-server
echo "Restart DHCP Server..."
sudo systemctl restart isc-dhcp-server
check_status "Restart isc-dhcp-server"

# Akhir
check_akhir
clear

# Dokumentasi
# -eq 0: Mengecek apakah kode status sama dengan 0 (menandakan instalasi berhasil).
# -ne 0: Mengecek apakah nilai kode status tidak sama
# $?: Menyimpan kode status dari perintah terakhir yang dijalankan. Kode status 0 berarti perintah berhasil, sedangkan nilai lain menunjukkan kegagalan.
