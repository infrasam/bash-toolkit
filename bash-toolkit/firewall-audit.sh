#!/usr/bin/env bash
# firewall-audit.sh — Audit firewall rules regardless of firewall tool
# Usage: sudo ./firewall-audit.sh

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

section "FIREWALL TYPE"
# Detect which firewall is active on this system
if command -v ufw > /dev/null 2>&1 && sudo ufw status | grep -q "active"; then
    fw_type="ufw"
    echo "[DETECTED] UFW (Uncomplicated Firewall)"
elif command -v firewall-cmd > /dev/null 2>&1 && sudo firewall-cmd --state 2>/dev/null | grep -q "running"; then
    fw_type="firewalld"
    echo "[DETECTED] firewalld"
elif command -v iptables > /dev/null 2>&1; then
    fw_type="iptables"
    echo "[DETECTED] iptables"
else
    echo "[WARNING] No firewall detected!"
    exit 0
fi

section "FIREWALL STATUS"
# Show current firewall status and rules
case "${fw_type}" in
    ufw)
        sudo ufw status verbose
        ;;
    firewalld)
        echo "Active zone:"
        sudo firewall-cmd --get-active-zones
        echo ""
        echo "Rules:"
        sudo firewall-cmd --list-all
        ;;
    iptables)
        # Show rules with packet counts, numeric addresses
        sudo iptables -L -n -v
        ;;
esac

section "OPEN PORTS vs FIREWALL"
# Compare listening ports against firewall rules to find mismatches
echo "Listening ports on this server:"
sudo ss -tlnp | tail -n +2 | awk '{print $4}' | rev | cut -d: -f1 | rev | sort -un | while read -r port; do
    process=$(sudo ss -tlnp | grep ":${port} " | grep -oP '"\K[^"]+' | head -1)
    # Check if port is allowed in firewall
    case "${fw_type}" in
        ufw)
            if sudo ufw status | grep -qw "${port}"; then
                echo "  [ALLOWED]  port ${port}  (${process})"
            else
                echo "  [NOT IN FW] port ${port}  (${process}) — open but no firewall rule"
            fi
            ;;
        firewalld)
            if sudo firewall-cmd --list-ports | grep -qw "${port}"; then
                echo "  [ALLOWED]  port ${port}  (${process})"
            else
                echo "  [NOT IN FW] port ${port}  (${process}) — open but no firewall rule"
            fi
            ;;
        iptables)
            if sudo iptables -L -n | grep -qw "${port}"; then
                echo "  [ALLOWED]  port ${port}  (${process})"
            else
                echo "  [NOT IN FW] port ${port}  (${process}) — open but no firewall rule"
            fi
            ;;
    esac
done