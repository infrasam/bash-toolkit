#!/usr/bin/env bash
# log-analyzer.sh — Analyze web server access logs (nginx/apache combined format)
# Usage: ./log-analyzer.sh <logfile>

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

# Store the first argument in a readable variable name
logfile="$1"

# Count number of lines - each line is one request
section "TOTAL REQUESTS"
wc -l < "$logfile"

# Extract IPs, count occurrences and show top 5 most active clients
section "TOP 5 IP ADDRESSES"
awk '{print $1}' "$logfile" | sort | uniq -c | sort -rn | head -5

# Extract status codes, count occurrences and show most common
section "STATUS CODE DISTRIBUTION"
awk '{print $9}' "$logfile" | sort | uniq -c | sort -rn | head -5

# Show all log lines with 5xx server errors
section "5XX SERVER ERRORS"
grep '" 5' "$logfile"
