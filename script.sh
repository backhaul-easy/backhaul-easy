#!/bin/bash

# =============================================
# Color Definitions
# =============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[1;36m'
GRAY='\033[0;90m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# =============================================
# ASCII Logo
# =============================================
LOGO="
${MAGENTA} ██████╗  █████╗  ██████╗██╗  ██╗██╗  ██╗ █████╗ ██╗   ██╗██╗     
${MAGENTA} ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║  ██║██╔══██╗██║   ██║██║     
${MAGENTA} ██████╔╝███████║██║     █████╔╝ ███████║███████║██║   ██║██║     
${MAGENTA} ██╔══██╗██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██║██║   ██║██║     
${MAGENTA} ██████╔╝██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╔╝███████╗
${MAGENTA} ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
${MAGENTA} ███████╗ █████╗ ███████╗██╗   ██╗
${MAGENTA} ██╔════╝██╔══██╗██╔════╝╚██╗ ██╔╝
${MAGENTA} █████╗  ███████║███████╗ ╚████╔╝ 
${MAGENTA} ██╔══╝  ██╔══██║╚════██║  ╚██╔╝  
${MAGENTA} ███████╗██║  ██║███████║   ██║   
${MAGENTA} ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   
${NC}"

# =============================================
# Cache Configuration
# =============================================
CACHE_DIR="$HOME/backhaul-easy/.cache"
IP_INFO_CACHE_FILE="$CACHE_DIR/ip_info.json"
VERSION_CACHE_FILE="$CACHE_DIR/version.txt"
CACHE_EXPIRY=3600  # Cache expiry time in seconds (1 hour)

# =============================================
# System Configuration
# =============================================
SCRIPT_DIR="$HOME/backhaul-easy"
SYS_PATH="/etc/sysctl.conf"
PROF_PATH="/etc/profile"

# Detect OS and set appropriate stat command
if [[ "$OSTYPE" == "darwin"* ]]; then
    STAT_CMD="stat -f %m"
else
    STAT_CMD="stat -c %Y"
fi

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# =============================================
# Cache Management Functions
# =============================================
is_cache_expired() {
    local cache_file="$1"
    if [ ! -f "$cache_file" ]; then
        return 0  # Cache file doesn't exist
    fi
    local cache_age=$(($(date +%s) - $($STAT_CMD "$cache_file")))
    [ "$cache_age" -gt "$CACHE_EXPIRY" ]
}

get_script_version() {
    if is_cache_expired "$VERSION_CACHE_FILE"; then
        local version
        version=$(curl -s https://api.github.com/repos/masihjahangiri/backhaul-easy/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
        if [ -z "$version" ]; then
            version="v1.0.0"  # Fallback version if API call fails
        fi
        echo "$version" > "$VERSION_CACHE_FILE"
    fi
    cat "$VERSION_CACHE_FILE"
}

# =============================================
# IP Information Functions
# =============================================
get_ip_info() {
    if is_cache_expired "$IP_INFO_CACHE_FILE"; then
        curl -s https://ipinfo.io/json > "$IP_INFO_CACHE_FILE"
    fi
    cat "$IP_INFO_CACHE_FILE"
}

get_location() {
    local ip_info
    ip_info=$(get_ip_info)
    local country_code=$(echo "$ip_info" | grep -o '"country": "[^"]*' | cut -d'"' -f4)
    
    # Convert country code to full name
    case "$country_code" in
        "DE") echo "Germany" ;;
        "US") echo "United States" ;;
        "GB") echo "United Kingdom" ;;
        "FR") echo "France" ;;
        "NL") echo "Netherlands" ;;
        "SG") echo "Singapore" ;;
        "JP") echo "Japan" ;;
        "CA") echo "Canada" ;;
        "AU") echo "Australia" ;;
        "BR") echo "Brazil" ;;
        "IN") echo "India" ;;
        "RU") echo "Russia" ;;
        "CN") echo "China" ;;
        "KR") echo "South Korea" ;;
        "IT") echo "Italy" ;;
        "ES") echo "Spain" ;;
        "SE") echo "Sweden" ;;
        "CH") echo "Switzerland" ;;
        "NO") echo "Norway" ;;
        "DK") echo "Denmark" ;;
        "FI") echo "Finland" ;;
        "PL") echo "Poland" ;;
        "AT") echo "Austria" ;;
        "BE") echo "Belgium" ;;
        "PT") echo "Portugal" ;;
        "IE") echo "Ireland" ;;
        "CZ") echo "Czech Republic" ;;
        "HU") echo "Hungary" ;;
        "RO") echo "Romania" ;;
        "GR") echo "Greece" ;;
        "BG") echo "Bulgaria" ;;
        "HR") echo "Croatia" ;;
        "SK") echo "Slovakia" ;;
        "SI") echo "Slovenia" ;;
        "EE") echo "Estonia" ;;
        "LV") echo "Latvia" ;;
        "LT") echo "Lithuania" ;;
        "CY") echo "Cyprus" ;;
        "LU") echo "Luxembourg" ;;
        "MT") echo "Malta" ;;
        "IS") echo "Iceland" ;;
        "IR") echo "Iran" ;;
        *) echo "$country_code" ;;
    esac
}

get_datacenter() {
    local ip_info
    ip_info=$(get_ip_info)
    local org=$(echo "$ip_info" | grep -o '"org": "[^"]*' | cut -d'"' -f4)
    # Remove AS number if present
    echo "$org" | sed 's/^AS[0-9]* //'
}

get_ip() {
    local ip_info
    ip_info=$(get_ip_info)
    echo "$ip_info" | grep -o '"ip": "[^"]*' | cut -d'"' -f4
}

# =============================================
# System Optimization Functions
# =============================================
ask_reboot() {
    echo -ne "${YELLOW}Reboot now? (Recommended) (y/n): ${NC}"
    while true; do
        read choice
        echo 
        if [[ "$choice" == 'y' || "$choice" == 'Y' ]]; then
            sleep 0.5
            reboot
            exit 0
        fi
        if [[ "$choice" == 'n' || "$choice" == 'N' ]]; then
            break
        fi
    done
}

sysctl_optimizations() {
    ## Make a backup of the original sysctl.conf file
    cp $SYS_PATH /etc/sysctl.conf.bak

    echo 
    echo -e "${YELLOW}Default sysctl.conf file Saved. Directory: /etc/sysctl.conf.bak${NC}"
    echo 
    sleep 1

    echo 
    echo -e "${YELLOW}Optimizing the Network...${NC}"
    echo 
    sleep 0.5

    # Remove existing parameters
    sed -i -e '/fs.file-max/d' \
        -e '/net.core.default_qdisc/d' \
        -e '/net.core.netdev_max_backlog/d' \
        -e '/net.core.optmem_max/d' \
        -e '/net.core.somaxconn/d' \
        -e '/net.core.rmem_max/d' \
        -e '/net.core.wmem_max/d' \
        -e '/net.core.rmem_default/d' \
        -e '/net.core.wmem_default/d' \
        -e '/net.ipv4.tcp_rmem/d' \
        -e '/net.ipv4.tcp_wmem/d' \
        -e '/net.ipv4.tcp_congestion_control/d' \
        -e '/net.ipv4.tcp_fastopen/d' \
        -e '/net.ipv4.tcp_fin_timeout/d' \
        -e '/net.ipv4.tcp_keepalive_time/d' \
        -e '/net.ipv4.tcp_keepalive_probes/d' \
        -e '/net.ipv4.tcp_keepalive_intvl/d' \
        -e '/net.ipv4.tcp_max_orphans/d' \
        -e '/net.ipv4.tcp_max_syn_backlog/d' \
        -e '/net.ipv4.tcp_max_tw_buckets/d' \
        -e '/net.ipv4.tcp_mem/d' \
        -e '/net.ipv4.tcp_mtu_probing/d' \
        -e '/net.ipv4.tcp_notsent_lowat/d' \
        -e '/net.ipv4.tcp_retries2/d' \
        -e '/net.ipv4.tcp_sack/d' \
        -e '/net.ipv4.tcp_dsack/d' \
        -e '/net.ipv4.tcp_slow_start_after_idle/d' \
        -e '/net.ipv4.tcp_window_scaling/d' \
        -e '/net.ipv4.tcp_adv_win_scale/d' \
        -e '/net.ipv4.tcp_ecn/d' \
        -e '/net.ipv4.tcp_ecn_fallback/d' \
        -e '/net.ipv4.tcp_syncookies/d' \
        -e '/net.ipv4.udp_mem/d' \
        -e '/net.ipv6.conf.all.disable_ipv6/d' \
        -e '/net.ipv6.conf.default.disable_ipv6/d' \
        -e '/net.ipv6.conf.lo.disable_ipv6/d' \
        -e '/net.unix.max_dgram_qlen/d' \
        -e '/vm.min_free_kbytes/d' \
        -e '/vm.swappiness/d' \
        -e '/vm.vfs_cache_pressure/d' \
        -e '/net.ipv4.conf.default.rp_filter/d' \
        -e '/net.ipv4.conf.all.rp_filter/d' \
        -e '/net.ipv4.conf.all.accept_source_route/d' \
        -e '/net.ipv4.conf.default.accept_source_route/d' \
        -e '/net.ipv4.neigh.default.gc_thresh1/d' \
        -e '/net.ipv4.neigh.default.gc_thresh2/d' \
        -e '/net.ipv4.neigh.default.gc_thresh3/d' \
        -e '/net.ipv4.neigh.default.gc_stale_time/d' \
        -e '/net.ipv4.conf.default.arp_announce/d' \
        -e '/net.ipv4.conf.lo.arp_announce/d' \
        -e '/net.ipv4.conf.all.arp_announce/d' \
        -e '/kernel.panic/d' \
        -e '/vm.dirty_ratio/d' \
        -e '/^#/d' \
        -e '/^$/d' \
        "$SYS_PATH"

    # Add new optimized parameters
    cat <<EOF >> "$SYS_PATH"

################################################################
################################################################

# /etc/sysctl.conf
# These parameters in this file will be added/updated to the sysctl.conf file.
# Read More: https://github.com/hawshemi/Linux-Optimizer/blob/main/files/sysctl.conf

## File system settings
## ----------------------------------------------------------------
fs.file-max = 67108864

## Network core settings
## ----------------------------------------------------------------
net.core.default_qdisc = fq_codel
net.core.netdev_max_backlog = 32768
net.core.optmem_max = 262144
net.core.somaxconn = 65536
net.core.rmem_max = 33554432
net.core.rmem_default = 1048576
net.core.wmem_max = 33554432
net.core.wmem_default = 1048576

## TCP settings
## ----------------------------------------------------------------
net.ipv4.tcp_rmem = 16384 1048576 33554432
net.ipv4.tcp_wmem = 16384 1048576 33554432
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fin_timeout = 25
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 7
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_max_orphans = 819200
net.ipv4.tcp_max_syn_backlog = 20480
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_mem = 65536 1048576 33554432
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_notsent_lowat = 32768
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = -2
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_ecn_fallback = 1
net.ipv4.tcp_syncookies = 1

## UDP settings
## ----------------------------------------------------------------
net.ipv4.udp_mem = 65536 1048576 33554432

## IPv6 settings
## ----------------------------------------------------------------
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0

## UNIX domain sockets
## ----------------------------------------------------------------
net.unix.max_dgram_qlen = 256

## Virtual memory (VM) settings
## ----------------------------------------------------------------
vm.min_free_kbytes = 65536
vm.swappiness = 10
vm.vfs_cache_pressure = 250

## Network Configuration
## ----------------------------------------------------------------
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.neigh.default.gc_thresh1 = 512
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh3 = 16384
net.ipv4.neigh.default.gc_stale_time = 60
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2
kernel.panic = 1
vm.dirty_ratio = 20

################################################################
################################################################

EOF

    sudo sysctl -p
    
    echo 
    echo -e "${GREEN}Network is Optimized.${NC}"
    echo 
    sleep 0.5
}

limits_optimizations() {
    echo
    echo -e "${YELLOW}Optimizing System Limits...${NC}"
    echo 
    sleep 0.5

    # Clear old ulimits
    sed -i '/ulimit -c/d' $PROF_PATH
    sed -i '/ulimit -d/d' $PROF_PATH
    sed -i '/ulimit -f/d' $PROF_PATH
    sed -i '/ulimit -i/d' $PROF_PATH
    sed -i '/ulimit -l/d' $PROF_PATH
    sed -i '/ulimit -m/d' $PROF_PATH
    sed -i '/ulimit -n/d' $PROF_PATH
    sed -i '/ulimit -q/d' $PROF_PATH
    sed -i '/ulimit -s/d' $PROF_PATH
    sed -i '/ulimit -t/d' $PROF_PATH
    sed -i '/ulimit -u/d' $PROF_PATH
    sed -i '/ulimit -v/d' $PROF_PATH
    sed -i '/ulimit -x/d' $PROF_PATH
    sed -i '/ulimit -s/d' $PROF_PATH

    # Add new optimized ulimits
    echo "ulimit -c unlimited" | tee -a $PROF_PATH
    echo "ulimit -d unlimited" | tee -a $PROF_PATH
    echo "ulimit -f unlimited" | tee -a $PROF_PATH
    echo "ulimit -i unlimited" | tee -a $PROF_PATH
    echo "ulimit -l unlimited" | tee -a $PROF_PATH
    echo "ulimit -m unlimited" | tee -a $PROF_PATH
    echo "ulimit -n 1048576" | tee -a $PROF_PATH
    echo "ulimit -q unlimited" | tee -a $PROF_PATH
    echo "ulimit -s -H 65536" | tee -a $PROF_PATH
    echo "ulimit -s 32768" | tee -a $PROF_PATH
    echo "ulimit -t unlimited" | tee -a $PROF_PATH
    echo "ulimit -u unlimited" | tee -a $PROF_PATH
    echo "ulimit -v unlimited" | tee -a $PROF_PATH
    echo "ulimit -x unlimited" | tee -a $PROF_PATH

    echo 
    echo -e "${GREEN}System Limits are Optimized.${NC}"
    echo 
    sleep 0.5
}

# =============================================
# Backhaul Functions
# =============================================
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
    echo -e "${YELLOW}1) Restricted Server${GRAY} - Inside restricted network (behind NAT/firewall)"
    echo -e "${YELLOW}2) Public Server${GRAY} - Outside restricted network (public access)"
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

# =============================================
# Main Menu
# =============================================
menu() {
    while true; do
        clear
        echo -e "$LOGO"
        echo -e "${CYAN} ═════════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                     ${MAGENTA}System Information${CYAN}                     ${NC}"
        echo -e "${CYAN} ═════════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN} ${GRAY}Script Version:${NC} ${GREEN}$(get_script_version)${CYAN}${NC}"
        echo -e "${CYAN} ${GRAY}IP Address:${NC}     ${GREEN}$(get_ip)${CYAN}${NC}"
        echo -e "${CYAN} ${GRAY}Location:${NC}       ${GREEN}$(get_location)${CYAN}${NC}"
        echo -e "${CYAN} ${GRAY}Datacenter:${NC}     ${GREEN}$(get_datacenter)${CYAN}${NC}"
        echo -e "${CYAN} ═════════════════════════════════════════════════════════════════${NC}"
        echo -e "\n${CYAN} Select an option:${NC}"
        echo -e " 1) System & Network Optimizations${NC}"
        echo -e " 2) Install Backhaul and Setup Tunnel${NC}"
        echo -e " 3) Manage Backhaul Tunnels${NC}"
        echo -e " 4) Update Script from GitHub${NC}"
        echo -e " 0) Exit${YELLOW}\n"
        read -rp " Enter your choice: " choice

        case $choice in
            1)
                hawshemi_script
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

# =============================================
# Script Update Function
# =============================================
update_script() {
    local script_url="https://raw.githubusercontent.com/masihjahangiri/backhaul-easy/main/script.sh"
    local tmp_script
    tmp_script="$(mktemp /tmp/bh-update.XXXXXX)"

    echo -e "${CYAN}Checking for updates...${NC}"

    # Clear version cache before update
    rm -f "$VERSION_CACHE_FILE"

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

# =============================================
# Hawshemi Script Function
# =============================================
hawshemi_script() {
    clear

    echo -e "${MAGENTA}Special thanks to Hawshemi, the author of optimizer script...${NC}"
    sleep 2
    
    # Get the operating system name
    os_name=$(lsb_release -is)

    echo -e 
    # Check if the operating system is Ubuntu
    if [ "$os_name" == "Ubuntu" ]; then
        echo -e "${GREEN}The operating system is Ubuntu.${NC}"
        sleep 1
    else
        echo -e "${RED} The operating system is not Ubuntu.${NC}"
        sleep 2
        return
    fi

    sysctl_optimizations
    limits_optimizations
    ask_reboot
    read -p "Press Enter to continue..."
}

# =============================================
# Script Entry Point
# =============================================
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

# Start the main menu
menu
