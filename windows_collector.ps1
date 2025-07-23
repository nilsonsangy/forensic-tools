# Prompt the user to enter the folder path for saving results
$resultFolder = Read-Host "Enter the folder path where you want the results to be saved (a folder with the hostname will be created inside this path)"

# Create a folder for the results
$hostname = $env:COMPUTERNAME
$computerResultFolder = Join-Path -Path $resultFolder -ChildPath "${hostname}_result"

if (Test-Path -Path $computerResultFolder) {
    Remove-Item -Path $computerResultFolder -Recurse -Force
    Write-Host "Old folder '$computerResultFolder' removed"
}

New-Item -ItemType Directory -Path $computerResultFolder | Out-Null
Write-Host "Folder '$computerResultFolder' created"

# Prompt the user to enter the Sysinternals folder path
$sysinternalsFolder = Read-Host "Enter the Sysinternals folder path"

# Collect date and time
Get-Date | Out-File -FilePath "$computerResultFolder\date-time.txt"
Get-TimeZone | Out-File -Append -FilePath "$computerResultFolder\date-time.txt"

# Collect computer serial number
Get-WmiObject -Class Win32_BIOS | Select-Object SerialNumber | Out-File -FilePath "$computerResultFolder\serialnumber.txt"

# Collect computer SID
& "$sysinternalsFolder\psgetsid.exe" -nobanner -accepteula | Out-File -FilePath "$computerResultFolder\SID.txt"

# Collect system information
systeminfo | Out-File -FilePath "$computerResultFolder\systeminfo.txt"
& "$sysinternalsFolder\psinfo.exe" -d -s -h -nobanner -accepteula | Out-File -Append -FilePath "$computerResultFolder\systeminfo.txt"

# Collect network interface information
ipconfig /all | Out-File -FilePath "$computerResultFolder\ipconfig.txt"

# Collect command history
(Get-History).CommandLine | Out-File -FilePath "$computerResultFolder\command-history.txt"

# Collect logged-on users
& "$sysinternalsFolder\psloggedon.exe" -nobanner -accepteula | Out-File -FilePath "$computerResultFolder\loggedon.txt"

# Collect network statistics
netstat -nabo | Out-File -FilePath "$computerResultFolder\netstat.txt"

# Collect route table
route print | Out-File -FilePath "$computerResultFolder\routes.txt"

# Collect network shares
net use | Out-File -FilePath "$computerResultFolder\network-shares.txt"

# Collect files opened on the network
net file | Out-File -FilePath "$computerResultFolder\open-files.txt"

# Collect active sessions from network shares
net sessions | Out-File -FilePath "$computerResultFolder\network-shares-sessions.txt"

# Collect process list
& "$sysinternalsFolder\pslist.exe" -nobanner -accepteula | Out-File -FilePath "$computerResultFolder\process-list.txt"

# Collect process list and modules
tasklist /M | Out-File -FilePath "$computerResultFolder\process-modules.txt"

# Collect processes from each logon session
& "$sysinternalsFolder\logonsessions.exe" -p -nobanner -accepteula | Out-File -FilePath "$computerResultFolder\process-logonsessions.txt"

# Collect scheduled tasks
schtasks /query /fo LIST /v | Out-File -FilePath "$computerResultFolder\scheduled-tasks.txt"

# Collect installed programs
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Out-File -FilePath "$computerResultFolder\installed-programs.txt"

# Collect Windows Event Logs (System, Application, Security)
Get-WinEvent -LogName System -MaxEvents 1000 | Export-Csv -Path "$computerResultFolder\eventlog-system.csv" -NoTypeInformation
Get-WinEvent -LogName Application -MaxEvents 1000 | Export-Csv -Path "$computerResultFolder\eventlog-application.csv" -NoTypeInformation
Get-WinEvent -LogName Security -MaxEvents 1000 | Export-Csv -Path "$computerResultFolder\eventlog-security.csv" -NoTypeInformation

# Collect user accounts
Get-LocalUser | Out-File -FilePath "$computerResultFolder\local-users.txt"

# Collect group memberships
Get-LocalGroup | ForEach-Object {
    Get-LocalGroupMember -Group $_.Name | Out-File -Append -FilePath "$computerResultFolder\group-memberships.txt"
}

# Collect running services
Get-Service | Out-File -FilePath "$computerResultFolder\services.txt"

# Collect autorun programs
& "$sysinternalsFolder\autoruns.exe" -a -nobanner -accepteula | Out-File -FilePath "$computerResultFolder\autoruns.txt"

# Collect user account information
wmic useraccount get /all | Out-File -FilePath "$computerResultFolder\useraccount-info.txt"

# Collect process integrity levels
Get-CimInstance Win32_Process | ForEach-Object {
    $process = Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
    if ($process) {
        $ownerInfo = (Get-WmiObject Win32_Process -Filter "ProcessId = $($_.ProcessId)" -ErrorAction SilentlyContinue).GetOwner()
        $integrityLevel = if ($ownerInfo) {
            if ($ownerInfo.Sid -match "S-1-16-(\d+)") { [int]$matches[1] } else { "Unknown" }
        } else {
            "Unknown"
        }
        [PSCustomObject]@{
            ProcessName = $_.Name
            ProcessId = $_.ProcessId
            IntegrityLevel = $integrityLevel
        }
    }
} | Out-File -FilePath "$computerResultFolder\process-integrity-levels.txt"

# Collect detailed process list
Get-Process | Select-Object Name, Id, CPU, WorkingSet, StartTime, Path | Out-File -FilePath "$computerResultFolder\detailed-process-list.txt"

# Collect shared folders and files
net share | Out-File -FilePath "$computerResultFolder\shared-folders.txt"

# Generate hashes.txt
Set-Location -Path $computerResultFolder
Get-ChildItem -File | ForEach-Object {
    Get-FileHash -Path $_.FullName -Algorithm SHA256 | ForEach-Object {
        "$($_.Hash) $($_.Path)" | Out-File -Append -FilePath "$computerResultFolder\hashes.txt"
    }
}

# Check if UAC is enabled
Write-Host "Checking if UAC is enabled"
(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA).EnableLUA | Out-File -FilePath "$computerResultFolder\uac-status.txt"

# Check if anonymous enumeration of SAM accounts and shares is enabled
Write-Host "Checking anonymous enumeration of SAM accounts and shares"
(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name RestrictAnonymous).RestrictAnonymous | Out-File -FilePath "$computerResultFolder\anonymous-enum-status.txt"

# Check if Remote Desktop is enabled
Write-Host "Checking if Remote Desktop is enabled"
(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections).fDenyTSConnections | Out-File -FilePath "$computerResultFolder\remote-desktop-status.txt"

# Check if antivirus is enabled and updated
Write-Host "Checking if antivirus is enabled and updated"
Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntiVirusProduct | Select-Object displayName,productState | Out-File -FilePath "$computerResultFolder\antivirus-status.txt"

# Check if Windows Firewall is enabled and updated
Write-Host "Checking if Windows Firewall is enabled and updated"
netsh advfirewall show allprofiles | Out-File -FilePath "$computerResultFolder\firewall-status.txt"

Write-Host "Volatile data extraction finished. Results saved in '$computerResultFolder'."
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
