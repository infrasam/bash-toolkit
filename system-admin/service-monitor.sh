#!/usr/bin/env bash
# service-monitor.sh — Check for failed services and report recent changes
# Usage: ./service-monitor.sh

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

section "SUMMARY"
# Count running and failed services for a quick overview
running=$(systemctl --type=service --state=running --no-legend | wc -l)
failed=$(systemctl --type=service --state=failed --no-legend | wc -l)
echo "Running: ${running}"
echo "Failed:  ${failed}"
if [[ ${failed} -eq 0 ]]; then
    echo "[OK] No failed services"
else
    echo "[WARNING] ${failed} service(s) have failed!"
fi

section "ENABLED BUT NOT RUNNING"
# Show enabled long-running services that should be active but aren't
systemctl list-units --type=service --state=inactive --no-pager --no-legend | while read -r line; do
    service=$(echo "${line}" | awk '{print $1}')
    enabled=$(systemctl is-enabled "${service}" 2>/dev/null)
    type=$(systemctl show "${service}" --property=Type --value 2>/dev/null)
    if [[ "${enabled}" == "enabled" && "${type}" != "oneshot" ]]; then
        echo "[DOWN] ${service}"
    fi
done

section "RECENTLY CHANGED (24H)"
# Show enabled services that stopped or failed in the last 24 hours
systemctl list-units --type=service --all --no-pager --no-legend | while read -r line; do
    service=$(echo "${line}" | awk '{print $1}')
    enabled=$(systemctl is-enabled "${service}" 2>/dev/null)
    type=$(systemctl show "${service}" --property=Type --value 2>/dev/null)
    if [[ "${enabled}" != "enabled" || "${type}" == "oneshot" ]]; then
        continue
    fi
    state=$(systemctl is-active "${service}" 2>/dev/null)
    # Only show services that are NOT running
    if [[ "${state}" == "active" ]]; then
        continue
    fi
    timestamp=$(systemctl show "${service}" --property=InactiveEnterTimestamp --value 2>/dev/null)
    if [[ -n "${timestamp}" && "${timestamp}" != "" ]]; then
        change_epoch=$(date -d "${timestamp}" +%s 2>/dev/null)
        now_epoch=$(date +%s)
        diff=$(( now_epoch - change_epoch ))
        if [[ ${diff} -lt 86400 ]]; then
            hours=$(( diff / 3600 ))
            minutes=$(( (diff % 3600) / 60 ))
            result=$(systemctl show "${service}" --property=Result --value 2>/dev/null)
            echo "[${state}]  ${service}  (${hours}h ${minutes}m ago)  result=${result}"
            journalctl -u "${service}" --no-pager -n 3 --output=short 2>/dev/null | while read -r logline; do
                echo "          └─ ${logline}"
            done
            # Check if someone manually stopped the service via sudo
            service_short="${service%.service}"
            since_time=$(date -d "${timestamp}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
            manual=$(journalctl _COMM=sudo --no-pager --since "${since_time}" 2>/dev/null | grep "${service_short}" | tail -1)
            if [[ -n "${manual}" ]]; then
                echo "          ⚠ MANUAL ACTION: ${manual}"
            fi
            echo ""
        fi
    fi
done

section "FAILED SERVICES"
# List any services that crashed unexpectedly with details
failed_list=$(systemctl --type=service --state=failed --no-legend)
if [[ -z "${failed_list}" ]]; then
    echo "[OK] No failed services"
else
    echo "${failed_list}"
    echo ""
    echo "${failed_list}" | awk '{print $1}' | while read service; do
        echo "--- ${service} ---"
        journalctl -u "${service}" --no-pager -n 5 2>/dev/null
        echo ""
    done
fi
