#!/usr/bin/env bash
# system-overview.sh — Quick Server Overview.

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

# Show hostname
section "HOSTNAME"
hostname

# Show distro, version and kernel
section "OS & KERNEL"
cat /etc/os-release | head -2
uname -s -r

# Show how long the server has been running
section "UPTIME"
uptime -p

# Show CPU cores
section "CPU"
echo "CPU cores: $(nproc)"

# Show memory usage
section "MEMORY"
free -h

# Show disk usage
section "DISK USAGE"
df -h

# Show all IPv4 addresses
section "IP ADDRESSES"
ip -4 addr show | grep inet

# Show which proccesses are listening on which TCP ports
section "LISTENING PORTS"
ss -tlnp | awk 'NR==1 || NR>1{print $1, $4, $6}' | column -t

# Show logged in users
section "LOGGED IN USERS"
who

# Show last reboot
section "LAST REBOOT"
last -1 reboot
