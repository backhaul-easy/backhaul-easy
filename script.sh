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

get_script_version() {
    local version
    version=$(curl -s https://api.github.com/repos/masihjahangiri/backhaul-easy/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
    if [ -z "$version" ]; then
        version="v1.0.0"  # Fallback version if API call fails
    fi
    echo "$version"
}

SCRIPT_VERSION=$(get_script_version)

[[ $EUID -ne 0 ]] && { echo -e "${RED}This script must be run as root${NC}"; exit 1; }

# Simple command alias installation
if [[ -f "$0" && ! "$0" =~ ^/dev/fd/ ]]; then
    CURRENT_PATH="$(realpath "$0")"
    BH_LINK="/usr/local/bin/bh"
    
    if sudo ln -sf "$CURRENT_PATH" "$BH_LINK" 2>/dev/null; then
        sudo chmod +x "$BH_LINK"
        echo -e "${GREEN}Successfully installed/updated 'bh' command${NC}"
    else
        echo -e "${YELLOW}Failed to install 'bh' command. You can still run the script directly${NC}"
    fi
fi

SCRIPT_DIR="$HOME/backhaul-easy"

get_ip_info() {
    local ip_info
    ip_info=$(curl -s https://ipinfo.io/json)
    echo "$ip_info"
}

get_location() {
    local ip_info
    ip_info=$(get_ip_info)
    echo "$ip_info" | grep -o '"country": "[^"]*' | cut -d'"' -f4
}

get_datacenter() {
    local ip_info
    ip_info=$(get_ip_info)
    echo "$ip_info" | grep -o '"org": "[^"]*' | cut -d'"' -f4
}

get_ip() {
    local ip_info
    ip_info=$(get_ip_info)
    echo "$ip_info" | grep -o '"ip": "[^"]*' | cut -d'"' -f4
}

menu() {
    while true; do
        clear
        echo -e "$LOGO"
        echo -e "${CYAN}Backhaul Easy ${SCRIPT_VERSION}${NC}"
        echo -e "${YELLOW}IP Address:${NC} $(get_ip)"
        echo -e "${YELLOW}Location:${NC} $(get_location)"
        echo -e "${YELLOW}Datacenter:${NC} $(get_datacenter)"
        echo -e "\n${CYAN}Select an option:${NC}"
        echo -e "${YELLOW}1) System & Network Optimizations${NC}"
        echo -e "${YELLOW}2) Install Backhaul and Setup Tunnel${NC}"
        echo -e "${YELLOW}3) Manage Backhaul Tunnels${NC}"
        echo -e "${YELLOW}4) Update Script from GitHub${NC}"
        echo -e "${YELLOW}0) Exit${NC}"
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
                update_script
                ;;
            0)
                clear
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option.${NC}"
                sleep 2
                ;;
        esac
    done
}

update_script() {
    local script_url="https://raw.githubusercontent.com/masihjahangiri/backhaul-easy/main/script.sh"
    local tmp_script
    tmp_script="$(mktemp /tmp/bh-update.XXXXXX)"

    echo -e "${CYAN}Checking for updates...${NC}"

    # Download new version
    if ! curl -fsSL "$script_url" -o "$tmp_script"; then
        rm -f "$tmp_script"
        echo -e "${RED}Failed to download update. Check your internet connection.${NC}"
        sleep 2
        return 1
    fi

    # Verify the downloaded script
    if ! bash -n "$tmp_script"; then
        rm -f "$tmp_script"
        echo -e "${RED}Downloaded script contains syntax errors. Update aborted.${NC}"
        sleep 2
        return 1
    fi

    chmod +x "$tmp_script"

    # Update current script
    if [[ -f "$0" ]]; then
        if sudo mv "$tmp_script" "$0"; then
            sudo chmod +x "$0"
            echo -e "${GREEN}Script updated successfully. Reloading...${NC}"
            sleep 2
            exec "$0"
        else
            rm -f "$tmp_script"
            echo -e "${RED}Failed to update script. Check permissions.${NC}"
            sleep 2
            return 1
        fi
    else
        # If running from curl, just execute the new version
        echo -e "${GREEN}Script updated successfully. Running new version...${NC}"
        sleep 2
        exec bash "$tmp_script"
    fi
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

    wget -q https://github.com/Musixal/Backhaul/releases/download/v0.6.5/backhaul_linux_${ARCH}.tar.gz -O "$SCRIPT_DIR/backhaul_linux_${ARCH}.tar.gz"
    tar -xzf "$SCRIPT_DIR/backhaul_linux_${ARCH}.tar.gz" -C "$SCRIPT_DIR" && cd "$SCRIPT_DIR" && rm backhaul_linux_${ARCH}.tar.gz LICENSE README.md

    echo -e "${CYAN}Select your server type:${NC}"
    echo -e "${YELLOW}1) Restricted Server${NC} - Inside restricted network (behind NAT/firewall)"
    echo -e "${YELLOW}2) Public Server${NC} - Outside restricted network (public access)"
    echo -e "${YELLOW}0) Back to Main Menu${NC}"
    read -rp "Enter your choice [0-2]: " TYPE

    [[ "$TYPE" == "0" ]] && return
    [[ ! $TYPE =~ ^[12]$ ]] && { echo -e "${RED}Invalid choice.${NC}"; sleep 2; return; }

    read -rp "Enter Tunnel Port: " TUNNEL_PORT
    read -rp "Enter Token: " TOKEN

    if [[ "$TYPE" == "1" ]]; then
        CONFIG="$SCRIPT_DIR/restricted${TUNNEL_PORT}.toml"
        SERVICE="backhaul-restricted${TUNNEL_PORT}"
    else
        CONFIG="$SCRIPT_DIR/public${TUNNEL_PORT}.toml"
        SERVICE="backhaul-public${TUNNEL_PORT}"
    fi

    if [[ "$TYPE" == "1" ]]; then
        read -rp "Port Forwarding (comma-separated): " PORTS
        PORT_ARRAY=$(echo "$PORTS" | sed 's/,/","/g')
        cat > "$CONFIG" <<EOF
[server]
bind_addr="0.0.0.0:${TUNNEL_PORT}"
transport="tcp"
token="${TOKEN}"
keepalive_period=75
nodelay=true
heartbeat=40
channel_size=2048
mux_con=8
mux_version=2
mux_framesize=32768
mux_recievebuffer=4194304
mux_streambuffer=2000000
sniffer=false
web_port=0
sniffer_log="/root/backhaul.json"
log_level="info"
proxy_protocol=false
tun_name="backhaul"
tun_subnet="10.10.10.0/24"
mtu=1500
accept_udp=false

ports=["${PORT_ARRAY}"]
EOF
    else
        read -rp "Enter Restricted Server IP: " RESTRICTED_IP
        cat > "$CONFIG" <<EOF
[client]
remote_addr="${RESTRICTED_IP}:${TUNNEL_PORT}"
transport="tcp"
token="${TOKEN}"
connection_pool=8
aggressive_pool=false
keepalive_period=75
dial_timeout=10
retry_interval=3
nodelay=true
mux_version=2
mux_framesize=32768
mux_recievebuffer=4194304
mux_streambuffer=2000000
sniffer=false
web_port=0
sniffer_log="/root/backhaul.json"
log_level="info"
tun_name="backhaul"
tun_subnet="10.10.10.0/24"
mtu=1500
EOF
    fi

    cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=Backhaul Tunnel
After=network.target
[Service]
ExecStart=$SCRIPT_DIR/backhaul -c $CONFIG
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable --now ${SERVICE}.service &>/dev/null
}

manage_tunnels() {
    while true; do
        clear
        # Get all backhaul tunnels regardless of their state
        TUNNELS=($(systemctl list-units --type=service --all --plain | grep backhaul- | awk '{print $1}' | sed 's/\.service$//' | grep -v '^$'))
        
        if [[ ${#TUNNELS[@]} -eq 0 ]]; then
            echo -e "${YELLOW}No Backhaul tunnels found.${NC}"
            sleep 2
            return
        fi

        echo -e "${CYAN}Select a Backhaul Tunnel (or 0 to go back):${NC}"
        for i in "${!TUNNELS[@]}"; do
            echo -e "${YELLOW}$((i+1)))${NC} ${TUNNELS[$i]}"
        done
        echo -e "${YELLOW}0) Back to Main Menu${NC}"
        read -rp "Enter number: " TUNNUM

        if [[ "$TUNNUM" == "0" ]]; then
            return
        elif ! [[ "$TUNNUM" =~ ^[0-9]+$ ]] || (( TUNNUM < 1 || TUNNUM > ${#TUNNELS[@]} )); then
            echo -e "${RED}Invalid selection.${NC}"
            sleep 2
            continue
        fi

        TUNNEL="${TUNNELS[$((TUNNUM-1))]}"
        CONFIG_FILE="$SCRIPT_DIR/${TUNNEL#backhaul-}.toml"

        while true; do
            clear
            echo -e "${CYAN}Tunnel: $TUNNEL${NC}"
            echo -e "${GREEN}Systemctl Status:${NC}"
            systemctl status "$TUNNEL" --no-pager | grep -E 'Loaded|Active|ExecStart'

            if [[ -f "$CONFIG_FILE" ]]; then
                echo -e "${CYAN}Tunnel Configuration Summary:${NC}"
                grep -E 'bind_addr|remote_addr|ports' "$CONFIG_FILE"
            fi

            echo -e "\n${YELLOW}1) View Logs (last 50 lines)${NC}"
            echo -e "${YELLOW}2) View Full Logs${NC}"
            echo -e "${YELLOW}3) Stop & Disable Tunnel${NC}"
            echo -e "${YELLOW}4) Restart / Enable & Start${NC}"
            echo -e "${YELLOW}5) Edit Tunnel Config${NC}"
            echo -e "${YELLOW}6) Remove Full Tunnel${NC}"
            echo -e "${YELLOW}0) Back${NC}"
            read -rp "Choose an action: " action

            case $action in
                1)
                    journalctl -u "$TUNNEL" -n 50 --no-pager
                    read -rp "Press Enter to continue..."
                    ;;
                2)
                    journalctl -u "$TUNNEL" --no-pager | less
                    ;;
                3)
                    systemctl stop "$TUNNEL"
                    systemctl disable "$TUNNEL"
                    echo -e "${YELLOW}Tunnel $TUNNEL stopped and disabled.${NC}"
                    sleep 2
                    ;;
                4)
                    systemctl enable "$TUNNEL"
                    systemctl restart "$TUNNEL"
                    echo -e "${GREEN}Tunnel $TUNNEL restarted and enabled.${NC}"
                    sleep 2
                    ;;
                5)
                    nano "$CONFIG_FILE"
                    ;;
                6)
                    echo -e "${YELLOW}Removing tunnel $TUNNEL...${NC}"
                    
                    # Check if service exists
                    if ! systemctl is-enabled "$TUNNEL" &>/dev/null; then
                        echo -e "${YELLOW}Service $TUNNEL is not enabled or does not exist.${NC}"
                    else
                        # Stop and disable the service
                        if ! systemctl stop "$TUNNEL"; then
                            echo -e "${RED}Failed to stop service $TUNNEL.${NC}"
                        fi
                        if ! systemctl disable "$TUNNEL"; then
                            echo -e "${RED}Failed to disable service $TUNNEL.${NC}"
                        fi
                    fi
                    
                    # Remove service file if it exists
                    if [[ -f "/etc/systemd/system/${TUNNEL}.service" ]]; then
                        if ! rm -f "/etc/systemd/system/${TUNNEL}.service"; then
                            echo -e "${RED}Failed to remove service file for $TUNNEL.${NC}"
                        fi
                    else
                        echo -e "${YELLOW}Service file for $TUNNEL does not exist.${NC}"
                    fi
                    
                    # Remove config file if it exists
                    if [[ -f "$CONFIG_FILE" ]]; then
                        if ! rm -f "$CONFIG_FILE"; then
                            echo -e "${RED}Failed to remove config file for $TUNNEL.${NC}"
                        fi
                    else
                        echo -e "${YELLOW}Config file for $TUNNEL does not exist.${NC}"
                    fi
                    
                    # Reload systemd to reflect changes
                    systemctl daemon-reload
                    
                    echo -e "${GREEN}Tunnel $TUNNEL removal process completed.${NC}"
                    sleep 2
                    break  # Exit the tunnel management menu after removal
                    ;;
                0)
                    break
                    ;;
                *)
                    echo -e "${RED}Invalid option.${NC}"
                    sleep 2
                    ;;
            esac
        done
    done
}

menu
