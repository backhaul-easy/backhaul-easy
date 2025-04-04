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
CONFIG_DIR="$SCRIPT_DIR/configs"
mkdir -p "$CONFIG_DIR"

menu() {
    while true; do
        clear
        echo -e "$LOGO"
        echo -e "${CYAN}Select an option:${NC}"
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

    echo -e "${CYAN}Choose setup type:${NC}\n${YELLOW}1) Iran Server${NC}\n${YELLOW}2) Kharej Server${NC}\n${YELLOW}0) Back to Main Menu${NC}"
    read -rp "Select option [0-2]: " TYPE

    [[ "$TYPE" == "0" ]] && return
    [[ ! $TYPE =~ ^[12]$ ]] && { echo -e "${RED}Invalid choice.${NC}"; sleep 2; return; }

    read -rp "Enter Tunnel Port: " TUNNEL_PORT
    read -rp "Enter Token: " TOKEN

    CONFIG="$CONFIG_DIR/${TYPE}_${TUNNEL_PORT}.toml"
    SERVICE="backhaul-${TYPE}_${TUNNEL_PORT}"

    if [[ "$TYPE" == "1" ]]; then
        read -rp "Port Forwarding (comma-separated): " PORTS
        PORT_ARRAY=$(echo "$PORTS" | sed 's/,/","/g')
        cat > "$CONFIG" <<EOF
[server]
bind_addr="0.0.0.0:${TUNNEL_PORT}"
transport="tcp"
token="${TOKEN}"
ports=["${PORT_ARRAY}"]
EOF
    else
        read -rp "Enter Iran Server IP: " IRAN_IP
        cat > "$CONFIG" <<EOF
[client]
remote_addr="${IRAN_IP}:${TUNNEL_PORT}"
token="${TOKEN}"
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
        # Get only active tunnels and filter out any empty lines
        mapfile -t TUNNELS < <(systemctl list-units --type=service --all --no-legend | grep backhaul- | awk '{print $1}' | grep -v '^$')
        
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
        CONFIG_FILE="$CONFIG_DIR/${TUNNEL#backhaul-}.toml"

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
                    # Stop and disable the service first
                    systemctl stop "$TUNNEL"
                    systemctl disable "$TUNNEL"
                    
                    # Remove service file
                    rm -f "/etc/systemd/system/${TUNNEL}.service"
                    
                    # Remove config file
                    rm -f "$CONFIG_FILE"
                    
                    # Reload systemd to reflect changes
                    systemctl daemon-reload
                    
                    echo -e "${GREEN}Tunnel $TUNNEL has been completely removed.${NC}"
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
