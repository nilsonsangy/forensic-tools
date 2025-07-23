# Author: Nilson Sangy
# https://github.com/nilsonsangy/forensic-tools/blob/main/windows_collector.ps1

Write-Host "Volatile data extraction script on Windows."
Write-Host "Run with admin privileges."
$resultsFolder = Read-Host "Insert the folder path where you want the result to be saved (a folder with the host name will be created inside this path)"

$computerName = $env:COMPUTERNAME
$targetFolder = Join-Path $resultsFolder "${computerName}_result"

# Remove old folder if exists
if (Test-Path $targetFolder) {
    Remove-Item -Path $targetFolder -Recurse -Force
    Write-Host "Old folder '$targetFolder' removed"
}

# Create result folder
New-Item -Path $targetFolder -ItemType Directory | Out-Null
Write-Host "Folder '$targetFolder' created"

# Ask for Sysinternals folder
$sysinternalsFolder = Read-Host "This script uses some tools of Sysinternals, so insert Sysinternals folder path in your system"

# Collect date and time
Get-Date | Out-File -FilePath "$targetFolder\date-time.txt"
Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty CurrentTimeZone | Out-File -Append "$targetFolder\date-time.txt"

# Collect computer serial number
Get-WmiObject Win32_BIOS | Select-Object -ExpandProperty SerialNumber | Out-File "$targetFolder\serialnumber.txt"

# Collect computer SID
& "$sysinternalsFolder\psgetsid.exe" -nobanner -accepteula | Out-File "$targetFolder\SID.txt"

# Collect system information
systeminfo | Out-File "$targetFolder\systeminfo.txt"
Add-Content "$targetFolder\systeminfo.txt" ""
Add-Content "$targetFolder\systeminfo.txt" ""
& "$sysinternalsFolder\psinfo.exe" -d -s -h -nobanner -accepteula | Out-File "$targetFolder\systeminfo.txt" -Append

# Collect network interfaces info
ipconfig /all | Out-File "$targetFolder\ipconfig.txt"

# Collect command history (PowerShell history)
(Get-Content (Get-PSReadlineOption).HistorySavePath) | Out-File "$targetFolder\command-history.txt"

# Collect logged on users
& "$sysinternalsFolder\psloggedon.exe" -nobanner -accepteula | Out-File "$targetFolder\loggedon.txt"

# Collect network statistics
netstat -nabo | Out-File "$targetFolder\netstat.txt"

# Collect route table
netstat -rn | Out-File "$targetFolder\routes.txt"

# Collect network shares
net use | Out-File "$targetFolder\network-shares.txt"

# Collect files opened on the network
net file | Out-File "$targetFolder\open-files.txt"

# Collect active sessions from network shares
net sessions | Out-File "$targetFolder\network-shares-sessions.txt"

# Collect process list
& "$sysinternalsFolder\pslist.exe" -nobanner -accepteula | Out-File "$targetFolder\process-list.txt"

# Collect process list and modules
tasklist /M | Out-File "$targetFolder\process-modules.txt"

# Collect processes from each logon session
& "$sysinternalsFolder\logonsessions.exe" -p -nobanner -accepteula | Out-File "$targetFolder\process-logonsessions.txt"

# Generate hashes.txt (requires fsum.exe in PATH or in Sysinternals folder)
$fsumPath = "fsum.exe"
if (-not (Get-Command $fsumPath -ErrorAction SilentlyContinue)) {
    $fsumPath = Join-Path $sysinternalsFolder "fsum.exe"
}
if (Test-Path $fsumPath) {
    Push-Location $targetFolder
    & $fsumPath -sha256 *.txt | Out-File "..\hashes.txt"
    Move-Item "..\hashes.txt" . -Force
    Pop-Location
    Write-Host "Hashes.txt generated."
} else {
    Write-Host "fsum.exe not found. Skipping hash generation." -ForegroundColor Yellow
}

Write-Host "Volatile data extraction finished."
Pause
