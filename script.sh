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

# Install short command alias "bh"
BH_LINK="/usr/local/bin/bh"
if [[ -f "$0" && ! "$0" =~ ^/dev/fd/ ]]; then
    CURRENT_PATH="$(realpath "$0")"
    
    # Check if we have write permissions
    if [[ ! -w /usr/local/bin ]]; then
        echo -e "${YELLOW}No write permissions in /usr/local/bin. Checking alternatives...${NC}"
        if [[ -w "$HOME/.local/bin" ]]; then
            BH_LINK="$HOME/.local/bin/bh"
            mkdir -p "$HOME/.local/bin"
            echo -e "${CYAN}Using $HOME/.local/bin instead${NC}"
        else
            echo -e "${RED}No suitable directory found with write permissions.${NC}"
            echo -e "${YELLOW}Please run with sudo or create a writable directory.${NC}"
            sleep 2
        fi
    fi

    # Handle broken symlink
    if [[ -L "$BH_LINK" && ! -e "$BH_LINK" ]]; then
        echo -e "${YELLOW}Found broken symlink at $BH_LINK${NC}"
        if sudo rm -f "$BH_LINK"; then
            echo -e "${GREEN}Removed broken symlink${NC}"
        else
            echo -e "${RED}Failed to remove broken symlink${NC}"
            sleep 2
        fi
    fi

    # Create or update symlink
    if [[ ! -e "$BH_LINK" ]]; then
        echo -e "${CYAN}Installing 'bh' command...${NC}"
        if sudo ln -s "$CURRENT_PATH" "$BH_LINK" 2>/dev/null; then
            sudo chmod +x "$BH_LINK"
            echo -e "${GREEN}Successfully installed 'bh' command at $BH_LINK${NC}"
            echo -e "${CYAN}You can now use 'bh' to run this script from anywhere${NC}"
        else
            echo -e "${YELLOW}Failed to create symlink. Trying to copy instead...${NC}"
            if sudo cp "$CURRENT_PATH" "$BH_LINK"; then
                sudo chmod +x "$BH_LINK"
                echo -e "${GREEN}Successfully copied script to $BH_LINK${NC}"
            else
                echo -e "${RED}Failed to install 'bh' command${NC}"
                echo -e "${YELLOW}You can still run the script directly from its current location${NC}"
            fi
        fi
        sleep 2
    elif [[ -L "$BH_LINK" && "$(realpath "$BH_LINK")" != "$CURRENT_PATH" ]]; then
        echo -e "${YELLOW}Updating existing 'bh' command...${NC}"
        if sudo ln -sf "$CURRENT_PATH" "$BH_LINK"; then
            echo -e "${GREEN}Successfully updated 'bh' command${NC}"
        else
            echo -e "${RED}Failed to update 'bh' command${NC}"
        fi
        sleep 2
    else
        echo -e "${CYAN}'bh' command is already correctly configured${NC}"
    fi
else
    echo -e "${YELLOW}Running from a temporary source; skipping alias install${NC}"
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
    local backup_script="$HOME/.backhaul-easy/script.sh.bak"

    echo -e "${CYAN}Checking for updates...${NC}"

    # Create backup directory
    mkdir -p "$HOME/.backhaul-easy"

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

    # Create backup of current script
    if [[ -f "$0" ]]; then
        cp "$0" "$backup_script"
        echo -e "${YELLOW}Created backup at $backup_script${NC}"
    fi

    # Determine where to save the update
    if [[ "$0" == /dev/fd/* || ! -w "$0" ]]; then
        if [[ -e /usr/local/bin/bh && -w /usr/local/bin/bh ]]; then
            if sudo cp "$tmp_script" /usr/local/bin/bh; then
                sudo chmod +x /usr/local/bin/bh
                echo -e "${GREEN}Update saved to /usr/local/bin/bh${NC}"
                echo -e "${CYAN}Next time, use ${YELLOW}bh${CYAN} to run the updated script${NC}"
                sleep 2
                return 0
            fi
        fi

        # Try user's home directory as fallback
        local home_script="$HOME/bh"
        if cp "$tmp_script" "$home_script"; then
            chmod +x "$home_script"
            echo -e "${GREEN}Update saved to: $home_script${NC}"
            echo -e "${CYAN}Next time, use ${YELLOW}$home_script${CYAN} to run the updated script${NC}"
            sleep 2
            return 0
        fi

        echo -e "${RED}Failed to save update to any location${NC}"
        rm -f "$tmp_script"
        return 1
    fi

    # Update current script
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
    tar -xzf backhaul_linux_${ARCH}.tar.gz -C "$SCRIPT_DIR" && rm backhaul_linux_${ARCH}.tar.gz LICENSE README.md

    echo -e "${CYAN}Choose setup type:${NC}\n${YELLOW}1) Iran Server${NC}\n${YELLOW}2) Kharej Server${NC}"
    read -rp "Select option [1/2]: " TYPE

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
        mapfile -t TUNNELS < <(systemctl list-units --type=service --all | grep backhaul- | awk '{print $1}')
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
