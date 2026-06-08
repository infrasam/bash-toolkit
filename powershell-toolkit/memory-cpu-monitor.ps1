# memory-cpu-monitor.ps1 — Show top memory and CPU consuming processes on Windows
# Usage: .\memory-cpu-monitor.ps1

function Section($title) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  $title"
    Write-Host "========================================"
}

Section "MEMORY OVERVIEW"
# Total, used and free physical memory in GB (same source as system-overview.ps1)
$os = Get-CimInstance Win32_OperatingSystem
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedGB  = [math]::Round($totalGB - $freeGB, 2)
$usedPct = [math]::Round($usedGB / $totalGB * 100, 1)
Write-Host "Total: ${totalGB} GB"
Write-Host "Used:  ${usedGB} GB (${usedPct}%)"
Write-Host "Free:  ${freeGB} GB"

Section "PAGE FILE STATUS"
# The Windows page file is the equivalent of Linux swap. Heavy, growing usage
# is a sign of memory pressure — the OS is spilling RAM to disk.
$pf = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue
if ($pf) {
    foreach ($p in $pf) {
        # AllocatedBaseSize and CurrentUsage are reported in MB
        $pfPct = if ($p.AllocatedBaseSize -gt 0) {
            [math]::Round($p.CurrentUsage / $p.AllocatedBaseSize * 100, 1)
        } else { 0 }
        Write-Host "$($p.Name)"
        Write-Host "  Allocated: $($p.AllocatedBaseSize) MB"
        Write-Host "  In use:    $($p.CurrentUsage) MB (${pfPct}%)"
    }
} else {
    Write-Host "[INFO] No page file reported (a system-managed page file may not appear here)"
}

Section "TOP 10 MEMORY PROCESSES"
# WorkingSet64 = physical RAM the process is currently using (in bytes).
# We build one custom object per process, then Format-Table aligns the
# columns the same way 'column -t' does in the Bash version.
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 | ForEach-Object {
    [PSCustomObject]@{
        Process      = $_.ProcessName
        PID          = $_.Id
        'Memory(MB)' = [math]::Round($_.WorkingSet64 / 1MB, 1)
        'CPU(s)'     = [math]::Round($_.CPU, 1)
    }
} | Format-Table -AutoSize

Section "TOP 10 CPU PROCESSES"
# NOTE: .CPU is the TOTAL processor seconds a process has used since it
# started — NOT a live percentage like Linux 'ps %CPU'. A process that ran
# hard an hour ago still shows a high number even if it is idle right now.
# For a live snapshot you would use Get-Counter '\Process(*)\% Processor Time'.
Get-Process | Where-Object { $_.CPU } | Sort-Object CPU -Descending | Select-Object -First 10 | ForEach-Object {
    [PSCustomObject]@{
        Process      = $_.ProcessName
        PID          = $_.Id
        'CPU(s)'     = [math]::Round($_.CPU, 1)
        'Memory(MB)' = [math]::Round($_.WorkingSet64 / 1MB, 1)
    }
} | Format-Table -AutoSize
