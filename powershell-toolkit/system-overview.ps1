# system-overview.ps1 — Quick overview of a Windows server
# Usage: .\system-overview.ps1

function Section($title) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  $title"
    Write-Host "========================================"
}

Section "HOSTNAME"
$env:COMPUTERNAME

Section "OS & VERSION"
# Get OS name and version
(Get-CimInstance Win32_OperatingSystem).Caption
(Get-CimInstance Win32_OperatingSystem).Version

Section "UPTIME"
# Calculate how long the system has been running
$boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $boot
Write-Host "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"

Section "CPU"
# Show CPU model and core count
$cpu = Get-CimInstance Win32_Processor
Write-Host "Model: $($cpu.Name)"
Write-Host "Cores: $($cpu.NumberOfCores)"

Section "MEMORY"
# Show total and available memory in GB
$os = Get-CimInstance Win32_OperatingSystem
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedGB = [math]::Round($totalGB - $freeGB, 2)
Write-Host "Total: ${totalGB} GB"
Write-Host "Used:  ${usedGB} GB"
Write-Host "Free:  ${freeGB} GB"

Section "DISK USAGE"
# Show disk space for all fixed drives with volume label
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $label = if ($_.VolumeName) { $_.VolumeName } else { "No Label" }
    $totalGB = [math]::Round($_.Size / 1GB, 2)
    $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
    $usedPercent = [math]::Round(($totalGB - $freeGB) / $totalGB * 100, 1)
    Write-Host "$($_.DeviceID)  [$label]  Total: ${totalGB}GB  Free: ${freeGB}GB  Used: ${usedPercent}%"
}

Section "IP ADDRESSES"
# Show all IPv4 addresses except loopback
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' } | ForEach-Object {
    Write-Host "$($_.InterfaceAlias): $($_.IPAddress)"
}

Section "LISTENING PORTS"
# Show listening TCP ports with process names
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Sort-Object LocalPort -Unique | ForEach-Object {
    $proc = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
    Write-Host "port $($_.LocalPort)  ($proc)"
} | Select-Object -First 20

Section "LOGGED IN USERS"
query user 2>$null

Section "LAST REBOOT"
# Show when the system was last restarted
$boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Host "Last boot: $boot"
