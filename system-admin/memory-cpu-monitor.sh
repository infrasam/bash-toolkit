#!/usr/bin/env bash
# memory-cpu-monitor.sh — Show top memory and CPU consuming processes
# Usage: ./memory-cpu-monitor.sh

section() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

section "MEMORY OVERVIEW"
# Show total, used, free and available memory
free -h

section "SWAP STATUS"
# Show swap usage — if swap is heavily used, the system is under memory pressure
free -h | grep -i swap

section "TOP 10 MEMORY PROCESSES"
# Show processes using the most memory
ps aux --sort=-%mem | grep -v '\[' | awk 'NR==1{print "USER", "%MEM", "%CPU", "COMMAND"} NR>1{print $1, $4, $3, $11}' | head -11 | column -t

section "TOP 10 CPU PROCESSES"
# Show processes using the most CPU (column 3 = %CPU)
ps aux --sort=-%cpu | grep -v '\[' | awk 'NR==1{print "USER", "%MEM", "%CPU", "COMMAND"} NR>1{print $1, $4, $3, $11}' | head -11 | column -t
