:: Author: Nilson Sangy
:: https://github.com/nilsonsangy/tools

@echo off

echo Volatile data extraction script on Windows.
echo Run with admin privileges.
set /p resultFolder="Insert the folder path where you want the result to be saved. A folder with the host name will be created inside this path."
rd /s /q "%resultFolder%\%computername%_result"
mkdir "%resultFolder%\%computername%_result"
set COMPUTERNAMERESULT="%resultFolder%\%computername%_result"

:: Insert the Sysinternals path here
set /p sysinternalsFolder="This script uses some tools of Sysinternals, so insert Sysinternals folder path in your system."

echo Collecting date and time
date /t > %COMPUTERNAMERESULT%\date-time.txt
time /t >> %COMPUTERNAMERESULT%\date-time.txt
systeminfo | find Fuso >> %COMPUTERNAMERESULT%\date-time.txt
systeminfo | find Time Zone >> %COMPUTERNAMERESULT%\date-time.txt

echo Collecting computer serial number
wmic bios get serialnumber > %COMPUTERNAMERESULT%\serialnumber.txt

echo Collecting computer SID
%sysinternalsFolder%psgetsid -nobanner -accepteula >> %COMPUTERNAMERESULT%\SID.txt

echo Collecting system information
systeminfo > %COMPUTERNAMERESULT%\systeminfo.txt
echo: >> %COMPUTERNAMERESULT%\systeminfo.txt
echo: >> %COMPUTERNAMERESULT%\systeminfo.txt
%sysinternalsFolder%psinfo -d -s -h -nobanner -accepteula >> %COMPUTERNAMERESULT%\systeminfo.txt

echo Collecting information from network interfaces
ipconfig /all > %COMPUTERNAMERESULT%\ipconfig.txt

echo Collecting command history
doskey /history > %COMPUTERNAMERESULT%\command-history.txt

echo Collecting logged on users
%sysinternalsFolder%psloggedon -nobanner -accepteula > %COMPUTERNAMERESULT%\loggedon.txt

echo Collecting network statistics
netstat -nabo > %COMPUTERNAMERESULT%\netstat.txt

echo Collecting route table
netstat -rn > %COMPUTERNAMERESULT%\routes.txt

echo Collecting network shares
net use > %COMPUTERNAMERESULT%\network-shares.txt

echo Collecting files opened on the network
net file > %COMPUTERNAMERESULT%\open-files.txt

echo Collecting active sessions from network shares
net sessions > %COMPUTERNAMERESULT%\network-shares-sessions.txt

echo Collecting process list
%sysinternalsFolder%pslist -nobanner -accepteula > %COMPUTERNAMERESULT%\process-list.txt

echo Collecting process list and modules
tasklist /M > %COMPUTERNAMERESULT%\process-modules.txt

echo Collecting processes from each logon session
%sysinternalsFolder%logonsessions -p -nobanner -accepteula > %COMPUTERNAMERESULT%\process-logonsessions.txt

echo Generating hashes.txt
cd %COMPUTERNAMERESULT%\
fsum -sha256 *.txt > ..\hashes.txt
move ..\hashes.txt .
echo "Volatile data extraction finished."