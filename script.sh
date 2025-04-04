#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

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

[[ $EUID -ne 0 ]] && { echo -e "${RED}This script must be run as root${NC}"; exit 1; }

menu() {
    clear
    echo -e "$LOGO"
    echo -e "${CYAN}Select an option:${NC}"
    echo -e "${YELLOW}1) System & Network Optimizations${NC}"
    echo -e "${YELLOW}2) Install Backhaul and Setup Tunnel${NC}"
    echo -e "${YELLOW}3) Manage Backhaul Tunnels${NC}"
    echo -e "${YELLOW}4) Exit${NC}"
    read -rp "Enter your choice: " choice

    case $choice in
        1)
            sysctl_optimizations
            limits_optimizations
            read -rp "Reboot now? (y/n): " REBOOT
            [[ $REBOOT =~ ^[Yy]$ ]] && reboot
            ;;
        2)
            setup_backhaul
            ;;
        3)
            manage_tunnels
            ;;
        4)
            clear; exit 0
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"; sleep 2
            ;;
    esac
    menu
}

sysctl_optimizations() {
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    sed -i '/^#/d;/^$/d' /etc/sysctl.conf
    cat <<EOF >> /etc/sysctl.conf
fs.file-max = 67108864
net.core.default_qdisc = fq_codel
net.core.netdev_max_backlog = 32768
net.core.optmem_max = 262144
net.core.somaxconn = 65536
EOF
    sysctl -p &>/dev/null
}

limits_optimizations() {
    sed -i '/ulimit/d' /etc/profile
    echo "ulimit -n 1048576" >> /etc/profile
}

detect_arch() {
    case $(uname -m) in
        x86_64) echo amd64 ;;
        aarch64) echo arm64 ;;
        *) echo unsupported ;;
    esac
}

setup_backhaul() {
    ARCH=$(detect_arch)
    [[ "$ARCH" == "unsupported" ]] && { echo -e "${RED}Unsupported architecture.${NC}"; sleep 2; return; }

    wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_${ARCH}.tar.gz
    tar -xzf backhaul_linux_${ARCH}.tar.gz && rm backhaul_linux_${ARCH}.tar.gz LICENSE README.md

    echo -e "${CYAN}Choose setup type:${NC}\n${YELLOW}1) Iran Server${NC}\n${YELLOW}2) Kharej Server${NC}"
    read -rp "Select option [1/2]: " TYPE

    [[ ! $TYPE =~ ^[12]$ ]] && { echo -e "${RED}Invalid choice.${NC}"; sleep 2; return; }

    read -rp "Enter Tunnel Port: " TUNNEL_PORT
    read -rp "Enter Token: " TOKEN

    if [[ "$TYPE" == "1" ]]; then
        read -rp "Port Forwarding (comma-separated): " PORTS
        PORT_ARRAY=$(echo "$PORTS" | sed 's/,/","/g')
        CONFIG="iran${TUNNEL_PORT}.toml"
        cat > $CONFIG <<EOF
[server]
bind_addr="0.0.0.0:${TUNNEL_PORT}"
transport="tcp"
token="${TOKEN}"
ports=["${PORT_ARRAY}"]
EOF
        SERVICE="backhaul-iran${TUNNEL_PORT}"
    else
        read -rp "Enter Iran Server IP: " IRAN_IP
        CONFIG="kharej${TUNNEL_PORT}.toml"
        cat > $CONFIG <<EOF
[client]
remote_addr="${IRAN_IP}:${TUNNEL_PORT}"
token="${TOKEN}"
EOF
        SERVICE="backhaul-kharej${TUNNEL_PORT}"
    fi

    cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=Backhaul Tunnel
After=network.target

[Service]
ExecStart=/root/backhaul -c /root/$CONFIG
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable --now ${SERVICE}.service &>/dev/null
    clear
}

manage_tunnels() {
    clear
    mapfile -t TUNNELS < <(systemctl list-units --type=service --all | grep backhaul- | awk '{print $1}')
    if [[ ${#TUNNELS[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No Backhaul tunnels found.${NC}"; sleep 2; return
    fi

    echo -e "${CYAN}Select a Backhaul Tunnel:${NC}"
    for i in "${!TUNNELS[@]}"; do
        echo -e "${YELLOW}$((i+1)))${NC} ${TUNNELS[$i]}"
    done
    read -rp "Enter number: " TUNNUM

    if ! [[ "$TUNNUM" =~ ^[0-9]+$ ]] || (( TUNNUM < 1 || TUNNUM > ${#TUNNELS[@]} )); then
        echo -e "${RED}Invalid selection.${NC}"; sleep 2; return
    fi

    TUNNEL="${TUNNELS[$((TUNNUM-1))]}"
    clear
    echo -e "${CYAN}Tunnel: $TUNNEL${NC}"
    systemctl status "$TUNNEL" --no-pager | grep -E 'Loaded|Active|ExecStart'

    echo -e "\n${YELLOW}1) View Logs${NC}\n${YELLOW}2) Stop & Remove Tunnel${NC}\n${YELLOW}3) Back${NC}"
    read -rp "Choose an action: " action

    case $action in
        1)
            journalctl -u "$TUNNEL" --no-pager | less
            ;;
        2)
            systemctl stop "$TUNNEL"
            systemctl disable "$TUNNEL"
            rm -f "/etc/systemd/system/$TUNNEL"
            rm -f "/root/${TUNNEL#backhaul-}.toml"
            echo -e "${GREEN}Tunnel $TUNNEL removed.${NC}"; sleep 2
            ;;
        3)
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"; sleep 2
            ;;
    esac
    manage_tunnels
}

menu
