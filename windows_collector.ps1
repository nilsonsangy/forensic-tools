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

Write-Host "Volatile data extraction finished. Results saved in '$computerResultFolder'."