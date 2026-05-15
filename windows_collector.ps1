param(
    [string]$ResultsFolder,
    [string]$SysinternalsFolder
)

# Relaunch elevated if not running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Script is not running as Administrator. Relaunching with elevated privileges..."
    Start-Process -FilePath powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# If no results folder was passed, default to the current user's Downloads folder
if (-not $ResultsFolder -or $ResultsFolder -eq "") {
    $ResultsFolder = Join-Path $env:USERPROFILE "Downloads"
}

# Map parameter values to variables used later in the script
$resultsFolder = $ResultsFolder
$sysinternalsFolder = $SysinternalsFolder

## Author: Nilson Sangy
## https://github.com/nilsonsangy/forensic-tools/blob/main/windows_collector.ps1

Write-Host "Volatile data extraction script on Windows."

# ensure results folder variable
$computerName = $env:COMPUTERNAME
$runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$targetFolder = Join-Path $resultsFolder "${computerName}_result_$runTimestamp"

# Remove old folder if exists
if (Test-Path $targetFolder) {
    Remove-Item -Path $targetFolder -Recurse -Force
    Write-Host "Old folder '$targetFolder' removed"
}

# Create result folder and dumps subfolder
New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $targetFolder "dumps") -ItemType Directory -Force | Out-Null
Write-Host "Folder '$targetFolder' created"

function Write-CommandOutput {
    param(
        [string]$FileName,
        [scriptblock]$Command
    )

    & $Command | Out-File -FilePath (Join-Path $targetFolder $FileName)
}

# Collect date and time
Get-Date | Out-File -FilePath "$targetFolder\date-time.txt"
Get-TimeZone | Out-File -Append -FilePath "$targetFolder\date-time.txt"

# Collect computer serial number
Get-CimInstance Win32_BIOS | Select-Object -ExpandProperty SerialNumber | Out-File -FilePath "$targetFolder\serialnumber.txt"

# Collect computer SID (if psgetsid available)
if ($sysinternalsFolder -and (Test-Path (Join-Path $sysinternalsFolder 'psgetsid.exe'))) {
    & "$(Join-Path $sysinternalsFolder 'psgetsid.exe')" -nobanner -accepteula | Out-File -FilePath "$targetFolder\SID.txt"
} else {
    whoami /user | Out-File -FilePath "$targetFolder\SID.txt"
}

# Collect system information
systeminfo | Out-File -FilePath "$targetFolder\systeminfo.txt"
if ($sysinternalsFolder -and (Test-Path (Join-Path $sysinternalsFolder 'psinfo.exe'))) {
    & "$(Join-Path $sysinternalsFolder 'psinfo.exe')" -d -s -h -nobanner -accepteula | Out-File -Append -FilePath "$targetFolder\systeminfo.txt"
} else {
    Get-CimInstance Win32_OperatingSystem | Out-File -Append -FilePath "$targetFolder\systeminfo.txt"
}

# Collect network interfaces info
ipconfig /all | Out-File -FilePath "$targetFolder\ipconfig-all.txt"

# Collect command history (PowerShell history)
try {
    (Get-Content (Get-PSReadlineOption).HistorySavePath) | Out-File "$targetFolder\powershell-history.txt"
} catch {
    Write-Host "Could not read PSReadline history" -ForegroundColor Yellow
}

# Collect logged on users
if ($sysinternalsFolder -and (Test-Path (Join-Path $sysinternalsFolder 'psloggedon.exe'))) {
    & "$(Join-Path $sysinternalsFolder 'psloggedon.exe')" -nobanner -accepteula | Out-File -FilePath "$targetFolder\loggedon.txt"
} else {
    query user | Out-File -FilePath "$targetFolder\loggedon.txt"
}

# Collect network statistics and routes
netstat -nabo | Out-File -FilePath "$targetFolder\netstat.txt"
netstat -rn | Out-File -FilePath "$targetFolder\routes.txt"

# Collect network shares and open files
net use | Out-File -FilePath "$targetFolder\network-shares.txt"
net file | Out-File -FilePath "$targetFolder\open-files.txt"
net sessions | Out-File -FilePath "$targetFolder\network-shares-sessions.txt"

# Collect process information
if ($sysinternalsFolder -and (Test-Path (Join-Path $sysinternalsFolder 'pslist.exe'))) {
    & "$(Join-Path $sysinternalsFolder 'pslist.exe')" -nobanner -accepteula | Out-File -FilePath "$targetFolder\process-list.txt"
} else {
    Get-Process | Out-File -FilePath "$targetFolder\process-list.txt"
}

tasklist /M | Out-File -FilePath "$targetFolder\process-modules.txt"

if ($sysinternalsFolder -and (Test-Path (Join-Path $sysinternalsFolder 'logonsessions.exe'))) {
    & "$(Join-Path $sysinternalsFolder 'logonsessions.exe')" -p -nobanner -accepteula | Out-File -FilePath "$targetFolder\process-logonsessions.txt"
} else {
    Get-CimInstance Win32_LogonSession | Out-File -FilePath "$targetFolder\process-logonsessions.txt"
}

# Collect scheduled tasks
schtasks /query /fo LIST /v | Out-File -FilePath "$targetFolder\scheduled-tasks.txt"

# Collect installed programs
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Out-File -FilePath "$targetFolder\installed-programs.txt"

# Collect Windows Event Logs (System, Application, Security)
Get-WinEvent -LogName System -MaxEvents 1000 | Format-List * -Force | Out-File -FilePath "$targetFolder\eventlog-system.txt"
Get-WinEvent -LogName Application -MaxEvents 1000 | Format-List * -Force | Out-File -FilePath "$targetFolder\eventlog-application.txt"
Get-WinEvent -LogName Security -MaxEvents 1000 | Format-List * -Force | Out-File -FilePath "$targetFolder\eventlog-security.txt"

# Collect user accounts and group memberships
Get-LocalUser | Out-File -FilePath "$targetFolder\local-users.txt"
Get-LocalGroup | ForEach-Object {
    Get-LocalGroupMember -Group $_.Name | Out-File -Append -FilePath "$targetFolder\group-memberships.txt"
}

# Collect running services
Get-Service | Out-File -FilePath "$targetFolder\services.txt"

# Collect Credential Guard information when available
if ($sysinternalsFolder -and (Test-Path (Join-Path $sysinternalsFolder 'dgreadiness_v3.6.exe'))) {
    $credentialGuardOutput = & (Join-Path $sysinternalsFolder 'dgreadiness_v3.6.exe') -status 2>&1
    if ($credentialGuardOutput) {
        $credentialGuardOutput | Out-File -FilePath "$targetFolder\credential-guard-info.txt"
    } else {
        Get-CimInstance Win32_DeviceGuard | Format-List * -Force | Out-File -FilePath "$targetFolder\credential-guard-info.txt"
    }
} else {
    Get-CimInstance Win32_DeviceGuard | Format-List * -Force | Out-File -FilePath "$targetFolder\credential-guard-info.txt"
}

# Collect autoruns if available
if ($sysinternalsFolder -and (Test-Path (Join-Path $sysinternalsFolder 'autoruns.exe'))) {
    $autorunsPath = Join-Path $sysinternalsFolder 'autoruns.exe'
    & $autorunsPath -a -nobanner -accepteula | Out-File -FilePath "$targetFolder\startup-persistence.txt"
} else {
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Run* -ErrorAction SilentlyContinue | Format-List * -Force | Out-File -FilePath "$targetFolder\startup-persistence.txt"
    Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue | Format-List * -Force | Out-File -Append -FilePath "$targetFolder\startup-persistence.txt"
    Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue | Format-List * -Force | Out-File -Append -FilePath "$targetFolder\startup-persistence.txt"
}

# Collect user account information
wmic useraccount get /all | Out-File -FilePath "$targetFolder\user-accounts.txt"

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
} | Out-File -FilePath "$targetFolder\process-integrity-levels.txt"

# Collect detailed process list
Get-Process | Select-Object Name, Id, CPU, WorkingSet, StartTime, Path | Out-File -FilePath "$targetFolder\process-detailed-list.txt"

# Collect shared folders and files
net share | Out-File -FilePath "$targetFolder\network-shares.txt"

# --- New: Collect drivers and driver binaries hashes
Get-CimInstance Win32_SystemDriver | Select-Object Name,State,StartMode,PathName,DisplayName | Out-File -FilePath "$targetFolder\drivers.txt"

$driverPaths = Get-CimInstance Win32_SystemDriver | ForEach-Object {
    $p = ($_.PathName -replace '"','') -replace ' -.*$',''
    if ($p -and (Test-Path $p)) { $p }
}
if ($driverPaths) {
    foreach ($p in $driverPaths) {
        try {
            $h = Get-FileHash -Path $p -Algorithm SHA256 -ErrorAction Stop
            "$($h.Hash) $p" | Out-File -Append -FilePath "$targetFolder\driver-hashes.txt"
        } catch {
            "Could not hash $p" | Out-File -Append -FilePath "$targetFolder\driver-hashes.txt"
        }
    }
}

# --- New: Memory dump using native MiniDump if available
$miniDumpSource = @"
using System;
using System.Runtime.InteropServices;
public static class MiniDumpNative {
    [DllImport("dbghelp.dll", SetLastError=true)]
    public static extern bool MiniDumpWriteDump(IntPtr hProcess, int processId, IntPtr hFile, int dumpType, IntPtr expParam, IntPtr userStreamParam, IntPtr callbackParam);
}
"@
Add-Type $miniDumpSource -ErrorAction SilentlyContinue
try {
    $lsass = Get-Process -Name lsass -ErrorAction SilentlyContinue
    if ($lsass) {
        $dumpPath = Join-Path $targetFolder 'dumps\lsass.dmp'
        $fileStream = [System.IO.File]::Open($dumpPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        try {
            $handle = $fileStream.SafeFileHandle.DangerousGetHandle()
            $dumpSucceeded = [MiniDumpNative]::MiniDumpWriteDump($lsass.Handle, $lsass.Id, $handle, 2, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero)
            if (-not $dumpSucceeded -or ((Test-Path $dumpPath) -and ((Get-Item $dumpPath).Length -eq 0))) {
                Remove-Item -Path $dumpPath -Force -ErrorAction SilentlyContinue
                Write-Host "Native MiniDump failed" -ForegroundColor Yellow
            }
        } finally {
            $fileStream.Dispose()
        }
    }
} catch {
    Write-Host "Native MiniDump failed" -ForegroundColor Yellow
}

# Generate hashes.txt for collected text files and driver files
$fsumPath = 'fsum.exe'
if (-not (Get-Command $fsumPath -ErrorAction SilentlyContinue) -and $sysinternalsFolder) {
    $fsumPath = Join-Path $sysinternalsFolder 'fsum.exe'
}
if (Test-Path $fsumPath) {
    Push-Location $targetFolder
    & $fsumPath -sha256 *.txt | Out-File "..\hashes.txt"
    Move-Item "..\hashes.txt" . -Force
    Pop-Location
    Write-Host "Hashes.txt generated."
} else {
    # fallback to Get-FileHash for each file
    Get-ChildItem -Path $targetFolder -Recurse -File | ForEach-Object {
        try {
            $hash = Get-FileHash -Path $_.FullName -Algorithm SHA256
            "$($hash.Hash) $($_.FullName)"
        } catch {
            "Could not hash $($_.FullName)"
        }
    } | Out-File -FilePath (Join-Path $targetFolder 'hashes.txt')
}

Write-Host "Volatile data extraction finished. Results saved in '$targetFolder'."
Pause
