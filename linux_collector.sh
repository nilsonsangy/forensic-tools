#!/bin/sh

# Author: Nilson Sangy
# https://github.com/nilsonsangy/forensic-tools

FOLDERRESULT=`cat /etc/hostname`

clear
rm -rf "$FOLDERRESULT"

echo "Creating evidence folder $FOLDERRESULT..."
mkdir "$FOLDERRESULT"

echo "Collecting computer general informations..."
HOSTNAME=`cat /etc/hostname`
echo "Computer Name: $HOSTNAME" > ./$FOLDERRESULT/general-informations.txt

echo "Collecting Installation date..."
disk=`df -h | grep '/$' | cut -d' ' -f1`
installation_date=`tune2fs -l $disk | grep created`
echo "$installation_date" >> ./$FOLDERRESULT/general-informations.txt

echo "Collecting OS uptime..."
ligado=`uptime`; echo "UPTIME: $ligado" >> ./$FOLDERRESULT/general-informations.txt
echo "\n" >> ./$FOLDERRESULT/general-informations.txt

echo "Collecting hardware informations..."
dmidecode -t 1 >> ./$FOLDERRESULT/general-informations.txt

echo "Collecting BIOS release date..."
bios_release=`dmidecode -s bios-release-date`; echo -e "\tBIOS Release Date: $bios_release" >> ./$FOLDERRESULT/general-informations.txt

echo "Collecting CPU informations..."
lscpu >> ./$FOLDERRESULT/general-informations.txt
echo "\n\n" >> ./$FOLDERRESULT/general-informations.txt

echo "Collecting disk informations..."
df -hT >> ./$FOLDERRESULT/general-informations.txt

echo "Collecting network informations..."
ip a > ./$FOLDERRESULT/ifconfig.txt

echo "Collecting date and time..."
date > ./$FOLDERRESULT/date_time.txt

echo "Collecting command history..."
cat ~/.bash_history > "./$FOLDERRESULT/history.txt"

echo "Collecting logged users..."
w > ./$FOLDERRESULT/w.txt

echo "Collecting Open files..."
lsof -n > ./$FOLDERRESULT/lsof.txt

echo "Collecting connections, ports and process..."
netstat -putan > ./$FOLDERRESULT/netstat.txt

echo "Collecting process list..."
ps aux > ./$FOLDERRESULT/ps.txt

echo "Collecting modules informations..."
lsmod > ./$FOLDERRESULT/modulos.txt 2> /dev/null

echo "Collecting installed packages..."
if command -v dpkg > /dev/null; then
    dpkg -l > ./$FOLDERRESULT/installed_packages.txt
elif command -v rpm > /dev/null; then
    rpm -qa > ./$FOLDERRESULT/installed_packages.txt
else
    echo "Package manager not supported" > ./$FOLDERRESULT/installed_packages.txt
fi

echo "Collecting users..."
if command -v getent > /dev/null; then
    getent passwd | cut -d: -f1 > ./$FOLDERRESULT/users.txt
else
    echo "Command 'getent' not found. Unable to collect users." > ./$FOLDERRESULT/users.txt
fi

echo "Hashing... "
sha256sum ./$FOLDERRESULT/*.txt > ./$FOLDERRESULT/hashes.txt

echo "Terminated."

