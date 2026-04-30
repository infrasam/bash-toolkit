#!/usr/bin/env bash
# network-diag.sh — Diagnose network connectivity to a host
# Usage: ./network-diag.sh <host> <port>

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

host="$1"
port="$2"

# Check that both arguments were provided
if [[ -z "${host}" || -z "${port}" ]]; then
    echo "Usage: ./network-diag.sh <host> <port>"
    echo "Example: ./network-diag.sh google.com 443"
    exit 1
fi

section "TARGET"
echo "Host: ${host}"
echo "Port: ${port}"

section "DNS LOOKUP"
ip=$(dig +short "${host}" | head -1)
if [[ -n "${ip}" ]]; then
    echo "[OK] ${host} resolves to ${ip}"
else
    echo "[FAIL] ${host} could not be resolved"
fi

section "PING TEST"
# Send 3 ping packets — note: some hosts block ping, check port instead
if ping -c 3 -W 2 "${host}" > /dev/null 2>&1; then
    echo "[OK] ${host} responds to ping"
    ping -c 3 -W 2 "${host}" | tail -1
else
    echo "[BLOCKED] ${host} does not respond to ping (may be blocked by firewall)"
fi

section "PORT CHECK"
if nc -z -w 3 "${host}" "${port}" 2>/dev/null; then
    echo "[OPEN] ${host}:${port} is reachable"
else
    echo "[CLOSED] ${host}:${port} is not reachable"
fi

section "ROUTE"
# Show the network path to the host
if command -v traceroute > /dev/null 2>&1; then
    traceroute -m 10 "${host}" 2>/dev/null
elif command -v tracepath > /dev/null 2>&1; then
    tracepath "${host}" 2>/dev/null | head -10
else
    echo "[SKIP] Neither traceroute nor tracepath is installed"
fi