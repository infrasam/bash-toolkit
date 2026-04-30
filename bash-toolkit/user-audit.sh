#!/usr/bin/env bash
# user-audit.sh — Audit user accounts, sudo access, and login history
# Usage: ./user-audit.sh

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

section "SUMMARY"
# Count real users (UID 1000+, excluding nobody at 65534)
total_users=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | wc -l)
sudo_users=$(getent group sudo 2>/dev/null | cut -d: -f4 | tr ',' '\n' | wc -l)
echo "Total user accounts: ${total_users}"
echo "Users with sudo: ${sudo_users}"

section "USER ACCOUNTS"
# List all real users with their UID, home directory and shell
awk -F: '$3 >= 1000 && $3 < 65534 {print $1, "uid="$3, $6, $7}' /etc/passwd | column -t

section "SUDO USERS"
# Show which users have sudo access
getent group sudo 2>/dev/null | cut -d: -f4 | tr ',' '\n' | while read -r user; do
    echo "[SUDO] ${user}"
done

section "SSH AUTHORIZED KEYS"
# Check which users have SSH keys configured for remote access
awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $6}' /etc/passwd | while read -r user homedir; do
    keyfile="${homedir}/.ssh/authorized_keys"
    if [[ -f "${keyfile}" ]]; then
        keycount=$(grep -c -v '^$' "${keyfile}" 2>/dev/null)
        if [[ ${keycount} -gt 0 ]]; then
            echo "[KEYS]   ${user} — ${keycount} authorized key(s)"
        else
            echo "[EMPTY]  ${user} — authorized_keys file exists but is empty"
        fi
    else
        echo "[NONE]   ${user} — no authorized keys"
    fi
done

section "LOGIN HISTORY"
# Show last login for each real user, flag those who never logged in
awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | while read -r user; do
    last_login=$(last -1 "${user}" 2>/dev/null | head -1)
    if [[ -z "${last_login}" ]] || echo "${last_login}" | grep -q "wtmp begins"; then
        echo "[NEVER]  ${user} — no login history found"
    else
        echo "[OK]     ${user} — ${last_login}"
    fi
done
