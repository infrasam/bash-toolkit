#!/usr/bin/env bash
# disk-monitor.sh — Monitor disk usage and find large files
# Usage: ./disk-monitor.sh

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

section "DISK USAGE OVERVIEW"
# Show disk usage for all partitions
df -h

section "PARTITION WARNINGS"
# Check each partition — warn if usage is above 80%
df -h | awk 'NR>1{gsub(/%/, "", $5); if($5 > 80) print "WARNING: "$6" is at "$5"%"}'

section "TOP 10 LARGEST FILES"
# Find the 10 biggest files on the system
find / -type f -exec du -h {} + 2>/dev/null | sort -rh | head -10

section "TOP 10 LARGEST DIRECTORIES"
# Show the 10 biggest directories under /
du -sh /* 2>/dev/null | sort -rh | head -10
