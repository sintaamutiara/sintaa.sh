#!/bin/bash


# Warna untuk output
GREEN='\033[1;32m'
NC='\033[0m'

# Fungsi untuk pesan sukses dan gagal
success_message() { echo -e "${GREEN}$1 berhasil!${NC}"; }
error_message() { echo -e "\033[1;31m$1 gagal!${NC}"; exit 1; }                                  

# Menampilkan pesan awal clear
cat << EOT >

     (_)       | |                           
 ___  _  _ __  | |_   __ _                   
/ __|| || '_ \ | __| / _` |                  
\__ \| || | | || |_ | (_| |                  
|___/|_||_| |_| \__| \__,_|           

# Otomasi Dimulai
echo "Otomasi Dimulai"

# Menambahkan Repository Kartolo
echo -e "${GREEN}${PROGRES[0]}${NC}"
REPO="http://kartolo.sby.datautama.net.id/ubuntu/"                                 
if ! grep -q "$REPO" /etc/apt/sources.list; then
    cat <<EOF | sudo tee /etc/apt/sources.list > /dev/null
deb ${REPO} focal main restricted universe multiverse
deb ${REPO} focal-updates main restricted universe multiverse
deb ${REPO} focal-security main restricted universe multiverse
deb ${REPO} focal-backports main restricted universe multiverse
deb ${REPO} focal-proposed main restricted universe multiverse
EOF
fi

# Update Paket
echo -e "${GREEN}${PROGRES[1]}${NC}"
sudo apt update -y > /dev/null 2>&1 || error_message "${PROGRES[1]}"

# Konfigurasi Netplan
echo -e "${GREEN}${PROGRES[2]}${NC}"
cat <<EOT | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: yes
    eth1:
      dhcp4: no
  vlans:
    eth1.10:
    
sudo netplan apply > /dev/null 2>&1 || error_message "${PROGRES[2]}"

# Instalasi ISC DHCP Server
echo -e "${GREEN}${PROGRES[3]}${NC}"
sudo apt install -y isc-dhcp-server > /dev/null 2>&1 || error_message "${PROGRES[3]}"

# Konfigurasi DHCP Server
echo -e "${GREEN}${PROGRES[4]}${NC}"
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF > /dev/null
subnet  netmask {
  range ;
  option domain-name-servers ;
  option subnet-mask ;
  option routers ;
  option broadcast-address ;
  default-lease-time 600;
  max-lease-time 7200;

  }
}
EOF
echo 'INTERFACESv4="eth1.10"' | sudo tee /etc/default/isc-dhcp-server > /dev/null
sudo systemctl restart isc-dhcp-server > /dev/null 2>&1 || error_message "${PROGRES[4]}"

# Aktifkan IP Forwarding
echo -e "${GREEN}${PROGRES[5]}${NC}"
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p > /dev/null 2>&1 || error_message "${PROGRES[5]}"

# Konfigurasi Masquerade dengan iptables
echo -e "${GREEN}${PROGRES[6]}${NC}"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE > /dev/null 2>&1 || error_message "${PROGRES[6]}"

# Instalasi iptables-persistent dengan otomatisasi
echo -e "${GREEN}${PROGRES[7]}${NC}"
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections > /dev/null 2>&1
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections > /dev/null 2>&1
sudo apt install -y iptables-persistent > /dev/null 2>&1 || error_message "${PROGRES[7]}"

# Menyimpan Konfigurasi iptables
echo -e "${GREEN}${PROGRES[8]}${NC}"
sudo sh -c "iptables-save > /etc/iptables/rules.v4" > /dev/null 2>&1 || error_message "${PROGRES[8]}"
sudo sh -c "ip6tables-save > /etc/iptables/rules.v6" > /dev/null 2>&1 || error_message "${PROGRES[8]}"

# Instalasi Expect
echo -e "${GREEN}${PROGRES[9]}${NC}"
if ! command -v expect > /dev/null; then
    sudo apt install -y expect > /dev/null 2>&1 || error_message "${PROGRES[9]}"
    success_message "${PROGRES[9]} berhasil"
else
    success_message "${PROGRES[9]} sudah terinstal"
fi

# Menambahkan ip route
ip route add ......... via ...............

