#!/usr/bin/env bash
# cert-checker.sh — Check SSL certificate expiry for remote domains and local files
# Usage: ./cert-checker.sh                          (scan local certificates)
#        ./cert-checker.sh google.com github.com    (check remote domains)

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

# Function to check a certificate and print status
check_expiry() {
    local name="$1"
    local expiry_date="$2"

    # Convert expiry date to epoch and calculate days remaining
    expiry_epoch=$(date -d "${expiry_date}" +%s 2>/dev/null)
    if [[ -z "${expiry_epoch}" ]]; then
        echo "[ERROR]   ${name} — could not parse date: ${expiry_date}"
        return
    fi
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

    # Print status based on days remaining
    if [[ ${days_left} -lt 0 ]]; then
        echo "[EXPIRED] ${name} — expired $(( days_left * -1 )) days ago!"
    elif [[ ${days_left} -lt 30 ]]; then
        echo "[WARNING] ${name} — expires in ${days_left} days (${expiry_date})"
    else
        echo "[OK]      ${name} — expires in ${days_left} days (${expiry_date})"
    fi
}

# If arguments are provided, check remote domains
if [[ $# -gt 0 ]]; then
    section "REMOTE CERTIFICATES"
    for domain in "$@"; do
        # Get the certificate expiry date from the remote server
        expiry_date=$(echo | openssl s_client -connect "${domain}:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        if [[ -z "${expiry_date}" ]]; then
            echo "[ERROR]   ${domain} — could not retrieve certificate"
            continue
        fi
        check_expiry "${domain}" "${expiry_date}"
    done
else
    # No arguments — scan local certificate files
    section "LOCAL CERTIFICATES"
    # Search common certificate directories for .pem and .crt files
    cert_files=$(find /etc/ssl /etc/nginx /etc/apache2 /etc/pki /etc/letsencrypt 2>/dev/null -type f \( -name "*.pem" -o -name "*.crt" \) 2>/dev/null)
    if [[ -z "${cert_files}" ]]; then
        echo "[OK] No local certificate files found"
    else
        echo "${cert_files}" | while read -r cert_file; do
            # Try to read expiry date from the file
            expiry_date=$(openssl x509 -noout -enddate -in "${cert_file}" 2>/dev/null | cut -d= -f2)
            if [[ -n "${expiry_date}" ]]; then
                check_expiry "${cert_file}" "${expiry_date}"
            fi
        done
    fi
fi
