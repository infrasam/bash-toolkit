#!/usr/bin/env bash
# package-audit.sh — Audit installed packages and available updates
# Usage: ./package-audit.sh

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

section "SUMMARY"
# Count total installed packages
total=$(dpkg -l 2>/dev/null | grep '^ii' | wc -l)
echo "Total installed packages: ${total}"

# Check for available updates
upgradable=$(apt list --upgradable 2>/dev/null | grep -c 'upgradable')
echo "Packages with updates: ${upgradable}"

# Check for security updates specifically
security=$(apt list --upgradable 2>/dev/null | grep -ic 'security')
if [[ ${security} -gt 0 ]]; then
    echo "[WARNING] ${security} security update(s) available!"
else
    echo "[OK] No security updates pending"
fi

# Check if reboot is required after previous updates
if [[ -f /var/run/reboot-required ]]; then
    echo "[WARNING] System reboot required!"
else
    echo "[OK] No reboot required"
fi

section "CRITICAL PACKAGES"
# Check versions of security-critical packages
for pkg in openssl openssh-server openssh-client sudo curl wget bash linux-image-generic; do
    version=$(dpkg -l "${pkg}" 2>/dev/null | grep '^ii' | awk '{print $3}')
    if [[ -n "${version}" ]]; then
        echo "[INSTALLED] ${pkg}  ${version}"
    else
        echo "[MISSING]   ${pkg}  — not installed"
    fi
done

section "SECURITY UPDATES"
# Show security updates separately — these should be prioritized
sec_updates=$(apt list --upgradable 2>/dev/null | grep -i 'security')
if [[ -n "${sec_updates}" ]]; then
    echo "${sec_updates}" | while read -r line; do
        pkg_name=$(echo "${line}" | cut -d'/' -f1)
        new_version=$(echo "${line}" | awk '{print $2}')
        echo "[SECURITY] ${pkg_name}  → ${new_version}"
    done
else
    echo "[OK] No security updates pending"
fi

section "OTHER UPDATES"
# Show non-security updates
other_updates=$(apt list --upgradable 2>/dev/null | grep 'upgradable' | grep -iv 'security')
if [[ -n "${other_updates}" ]]; then
    echo "${other_updates}" | while read -r line; do
        pkg_name=$(echo "${line}" | cut -d'/' -f1)
        new_version=$(echo "${line}" | awk '{print $2}')
        echo "[UPDATE]  ${pkg_name}  → ${new_version}"
    done
else
    echo "[OK] All non-security packages are up to date"
fi

section "UNNECESSARY PACKAGES"
# Show packages that can be removed — report only, never remove
orphans=$(apt autoremove --dry-run 2>/dev/null | grep "^Remv" | awk '{print $2}')
if [[ -n "${orphans}" ]]; then
    count=$(echo "${orphans}" | wc -l)
    echo "[INFO] ${count} package(s) no longer needed:"
    echo "${orphans}" | while read -r pkg; do
        echo "  ${pkg}"
    done
    echo ""
    echo "To remove, run: sudo apt autoremove"
else
    echo "[OK] No unnecessary packages found"
fi

section "RECENTLY INSTALLED"
# Show packages installed or updated in the last 7 days
if [[ -f /var/log/dpkg.log ]]; then
    changes=$(grep " install \| upgrade " /var/log/dpkg.log 2>/dev/null | tail -10)
    if [[ -n "${changes}" ]]; then
        echo "${changes}" | while read -r line; do
            date=$(echo "${line}" | awk '{print $1, $2}')
            action=$(echo "${line}" | awk '{print $3}')
            pkg=$(echo "${line}" | awk '{print $4}')
            echo "  [${action}] ${date}  ${pkg}"
        done
    else
        echo "[OK] No recent package changes"
    fi
else
    echo "[SKIP] dpkg log not available"
fi
