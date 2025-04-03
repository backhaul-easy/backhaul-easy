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
    net.core.rmem_max = 33554432
    net.core.rmem_default = 1048576
    net.core.wmem_max = 33554432
    net.core.wmem_default = 1048576
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
    net.ipv4.udp_mem = 65536 1048576 33554432
    net.ipv6.conf.all.disable_ipv6 = 0
    net.ipv6.conf.default.disable_ipv6 = 0
    net.ipv6.conf.lo.disable_ipv6 = 0
    net.unix.max_dgram_qlen = 256
    vm.min_free_kbytes = 65536
    vm.swappiness = 10
    vm.vfs_cache_pressure = 250
    EOF

    sysctl -p
    echo -e "${GREEN}Network optimization applied.${NC}"
}

# Ulimit Optimization
limits_optimizations() {
    sed -i '/ulimit/d' "$PROF_PATH"
    cat <<EOF >> "$PROF_PATH"

    ulimit -c unlimited
    ulimit -d unlimited
    ulimit -f unlimited
    ulimit -i unlimited
    ulimit -l unlimited
    ulimit -m unlimited
    ulimit -n 1048576
    ulimit -q unlimited
    ulimit -s -H 65536
    ulimit -s 32768
    ulimit -t unlimited
    ulimit -u unlimited
    ulimit -v unlimited
    ulimit -x unlimited
    EOF

    echo -e "${GREEN}System limits optimized.${NC}"
}

# Run optimization
clear
echo -e "$LOGO"
echo -e "${YELLOW}Running system & network optimizations...${NC}"
sysctl_optimizations
limits_optimizations