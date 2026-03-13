#!/usr/bin/env bash
# system-overview.sh — Quick Server Overview.

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

section "HOSTNAME"
hostname

section "OS & KERNEL"
cat /etc/os-release | head -2
uname -s -r

section "UPTIME"
uptime -p

section "CPU"
echo "CPU cores: $(nproc)"

section "MEMORY"
free -h

section "DISK USAGE"
df -h

section "IP ADDRESSES"
ip -4 addr show | grep inet

section "LISTENING PORTS"
ss -tlnp | awk 'NR==1 || NR>1{print $1, $4, $6}' | column -t

section "LOGGED IN USERS"
who

section "LAST REBOOT"
last -1 reboot
