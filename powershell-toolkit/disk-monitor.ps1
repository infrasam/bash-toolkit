# disk-monitor.ps1 — Monitor disk usage and find large files on Windows
# Usage: .\disk-monitor.ps1

function Section($title) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  $title"
    Write-Host "========================================"
}

Section "DISK USAGE OVERVIEW"
# Show all fixed drives with usage percentage
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $label = if ($_.VolumeName) { $_.VolumeName } else { "No Label" }
    $totalGB = [math]::Round($_.Size / 1GB, 2)
    $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
    $usedPercent = [math]::Round(($totalGB - $freeGB) / $totalGB * 100, 1)
    Write-Host "$($_.DeviceID)  [$label]  Total: ${totalGB}GB  Free: ${freeGB}GB  Used: ${usedPercent}%"
}

Section "PARTITION WARNINGS"
# Warn if any drive is above 80% usage
$warnings = 0
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $totalGB = [math]::Round($_.Size / 1GB, 2)
    $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
    $usedPercent = [math]::Round(($totalGB - $freeGB) / $totalGB * 100, 1)
    if ($usedPercent -gt 80) {
        Write-Host "[WARNING] $($_.DeviceID) is at ${usedPercent}%"
        $script:warnings++
    }
}
if ($warnings -eq 0) {
    Write-Host "[OK] All drives below 80%"
}

Section "TOP 10 LARGEST FILES (ALL DRIVES)"
# Find the 10 biggest files across all fixed drives
$allDrives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object -ExpandProperty DeviceID
$allFiles = foreach ($drive in $allDrives) {
    Get-ChildItem -Path "$drive\" -Recurse -File -ErrorAction SilentlyContinue
}
$allFiles | Sort-Object Length -Descending | Select-Object -First 10 | ForEach-Object {
    $sizeGB = [math]::Round($_.Length / 1GB, 2)
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    $size = if ($sizeGB -ge 1) { "${sizeGB} GB" } else { "${sizeMB} MB" }
    Write-Host "${size}  $($_.FullName)"
}

Section "TOP 10 LARGEST DIRECTORIES (ALL DRIVES)"
# Show biggest top-level directories across all fixed drives
$allDirs = foreach ($drive in $allDrives) {
    Get-ChildItem -Path "$drive\" -Directory -ErrorAction SilentlyContinue
}
$allDirs | ForEach-Object {
    $size = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    $sizeGB = [math]::Round($size / 1GB, 2)
    [PSCustomObject]@{ Size = $sizeGB; Path = $_.FullName }
} | Sort-Object Size -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "$($_.Size) GB  $($_.Path)"
}
