#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# ASCII Art Logo
LOGO="
${MAGENTA}██████╗  █████╗  ██████╗██╗  ██╗██╗  ██╗ █████╗ ██╗   ██╗██╗     
${MAGENTA}██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║  ██║██╔══██╗██║   ██║██║     
${MAGENTA}██████╔╝███████║██║     █████╔╝ ███████║███████║██║   ██║██║     
${MAGENTA}██╔══██╗██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██║██║   ██║██║     
${MAGENTA}██████╔╝██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╔╝███████╗
${MAGENTA}╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
${MAGENTA}███████╗ █████╗ ███████╗██╗   ██╗
${MAGENTA}██╔════╝██╔══██╗██╔════╝╚██╗ ██╔╝
${MAGENTA}█████╗  ███████║███████╗ ╚████╔╝ 
${MAGENTA}██╔══╝  ██╔══██║╚════██║  ╚██╔╝  
${MAGENTA}███████╗██║  ██║███████║   ██║   
${MAGENTA}╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   
${NC}"

# Check for root permission
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Interactive Menu
echo -e "$LOGO"
echo -e "${CYAN}Select an option:${NC}"
echo -e "${YELLOW}1) System & Network Optimizations${NC}"
echo -e "${YELLOW}2) Install Backhaul and Setup Tunnel${NC}"
read -rp "Enter your choice: " choice

SYS_PATH="/etc/sysctl.conf"
PROF_PATH="/etc/profile"

# Network Optimization
sysctl_optimizations() {
    cp $SYS_PATH /etc/sysctl.conf.bak
    echo -e "${YELLOW}Backup saved to /etc/sysctl.conf.bak${NC}"

    sed -i '/^#/d;/^$/d' "$SYS_PATH"
    cat <<EOF >> "$SYS_PATH"
fs.file-max = 67108864
net.core.default_qdisc = fq_codel
net.core.netdev_max_backlog = 32768
net.core.optmem_max = 262144
net.core.somaxconn = 65536
EOF

    sysctl -p
    echo -e "${GREEN}Network optimization applied.${NC}"
}

# Ulimit Optimization
limits_optimizations() {
    sed -i '/ulimit/d' "$PROF_PATH"
    cat <<EOF >> "$PROF_PATH"
ulimit -n 1048576
EOF
    echo -e "${GREEN}System limits optimized.${NC}"
}

# Backhaul Installation & Tunnel Setup
setup_backhaul() {
    read -rp "Architecture (amd64/arm64): " ARCH
    if [[ "$ARCH" == "amd64" ]]; then
        wget https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_amd64.tar.gz
        tar -xzf backhaul_linux_amd64.tar.gz && rm backhaul_linux_amd64.tar.gz LICENSE README.md
    elif [[ "$ARCH" == "arm64" ]]; then
        wget https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_arm64.tar.gz
        tar -xzf backhaul_linux_arm64.tar.gz && rm backhaul_linux_arm64.tar.gz LICENSE README.md
    else
        echo -e "${RED}Invalid architecture.${NC}"
        exit 1
    fi

    read -rp "Setup as (1) Iran Server or (2) Kharej Client? " TYPE
    read -rp "Enter Tunnel Port: " TUNNEL_PORT
    read -rp "Enter Token: " TOKEN

    if [[ "$TYPE" == "1" ]]; then
        cat > iran${TUNNEL_PORT}.toml <<EOF
[server]
bind_addr = "0.0.0.0:${TUNNEL_PORT}"
transport = "tcp"
token = "${TOKEN}"
ports = ["443"]
EOF
        cat > /etc/systemd/system/backhaul-iran${TUNNEL_PORT}.service <<EOF
[Service]
ExecStart=/root/backhaul -c /root/iran${TUNNEL_PORT}.toml
EOF
    elif [[ "$TYPE" == "2" ]]; then
        read -rp "Enter Iran Server IP: " IRAN_IP
        cat > kharej${TUNNEL_PORT}.toml <<EOF
[client]
remote_addr = "${IRAN_IP}:${TUNNEL_PORT}"
token = "${TOKEN}"
EOF
        cat > /etc/systemd/system/backhaul-kharej${TUNNEL_PORT}.service <<EOF
[Service]
ExecStart=/root/backhaul -c /root/kharej${TUNNEL_PORT}.toml
EOF
    else
        echo -e "${RED}Invalid choice.${NC}"
        exit 1
    fi

    systemctl enable --now backhaul-*
    echo -e "${GREEN}Backhaul installed and tunnel setup completed.${NC}"
}

case $choice in
    1)
        sysctl_optimizations
        limits_optimizations
        ;;
    2)
        setup_backhaul
        ;;
    *)
        echo -e "${RED}Invalid option.${NC}"
        ;;
esac
