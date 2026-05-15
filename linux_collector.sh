#!/bin/sh

# Author: Nilson Sangy
# https://github.com/nilsonsangy/forensic-tools

RESULTS_ROOT=$1
if [ -z "$RESULTS_ROOT" ]; then
    RESULTS_ROOT="$HOME/Downloads"
fi

if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        echo "This script needs elevated privileges for complete collection. Relaunching with sudo..."
        exec sudo sh "$0" "$RESULTS_ROOT"
    else
        echo "sudo is not available. Some data may be incomplete." >&2
    fi
fi

OUTPUT_OWNER=${SUDO_USER:-}
OUTPUT_GROUP=""
if [ -n "$OUTPUT_OWNER" ] && [ "$OUTPUT_OWNER" != "root" ]; then
    OUTPUT_GROUP=$(id -gn "$OUTPUT_OWNER" 2>/dev/null)
fi

HOSTNAME=$(cat /etc/hostname 2>/dev/null)
if [ -z "$HOSTNAME" ]; then
    HOSTNAME=$(hostname 2>/dev/null)
fi
if [ -z "$HOSTNAME" ]; then
    HOSTNAME="linux-host"
fi

RUN_TIMESTAMP=$(date +"%Y%m%d-%H%M%S" 2>/dev/null)
if [ -z "$RUN_TIMESTAMP" ]; then
    RUN_TIMESTAMP="unknown-time"
fi

FOLDERRESULT="${RESULTS_ROOT%/}/${HOSTNAME}_result_${RUN_TIMESTAMP}"

clear 2>/dev/null
rm -rf "$FOLDERRESULT"

echo "Creating evidence folder $FOLDERRESULT..."
mkdir -p "$FOLDERRESULT"

collect_if_exists() {
    if command -v "$1" >/dev/null 2>&1; then
        shift
        "$@"
    fi
}

echo "Collecting computer general informations..."
{
    echo "Computer Name: $HOSTNAME"
    echo "Uptime: $(uptime 2>/dev/null)"
    echo "Hostname: $HOSTNAME"
    echo
    echo "Kernel: $(uname -a 2>/dev/null)"
    echo
    echo "Filesystem and mount details:"
    df -hT 2>/dev/null
} > "$FOLDERRESULT/systeminfo.txt"

if command -v tune2fs >/dev/null 2>&1; then
    disk=$(df -h 2>/dev/null | awk '$NF == "/" { print $1; exit }')
    if [ -n "$disk" ]; then
        installation_date=$(tune2fs -l "$disk" 2>/dev/null | grep 'Filesystem created' | head -n 1)
        if [ -n "$installation_date" ]; then
            echo "$installation_date" >> "$FOLDERRESULT/systeminfo.txt"
        fi
    fi
fi

if command -v dmidecode >/dev/null 2>&1; then
    echo "Collecting hardware informations..."
    dmidecode -t 1 >> "$FOLDERRESULT/systeminfo.txt" 2>/dev/null
    bios_release=$(dmidecode -s bios-release-date 2>/dev/null)
    if [ -n "$bios_release" ]; then
        printf '\tBIOS Release Date: %s\n' "$bios_release" >> "$FOLDERRESULT/systeminfo.txt"
    fi
fi

if command -v lscpu >/dev/null 2>&1; then
    echo "Collecting CPU informations..."
    lscpu >> "$FOLDERRESULT/systeminfo.txt" 2>/dev/null
fi

echo "Collecting network informations..."
ip a > "$FOLDERRESULT/network-interfaces.txt" 2>/dev/null
ip route > "$FOLDERRESULT/routes.txt" 2>/dev/null

printf '%s\n' "$(date 2>/dev/null)" > "$FOLDERRESULT/date-time.txt"

if [ -f "$HOME/.bash_history" ]; then
    cp "$HOME/.bash_history" "$FOLDERRESULT/bash-history.txt" 2>/dev/null
else
    echo "No bash history file found." > "$FOLDERRESULT/bash-history.txt"
fi

w > "$FOLDERRESULT/logged-users.txt" 2>/dev/null
who > "$FOLDERRESULT/connected-users.txt" 2>/dev/null

if command -v lsof >/dev/null 2>&1; then
    lsof -n > "$FOLDERRESULT/lsof.txt" 2>/dev/null
fi

if command -v netstat >/dev/null 2>&1; then
    netstat -putan > "$FOLDERRESULT/netstat.txt" 2>/dev/null
else
    ss -tulpna > "$FOLDERRESULT/netstat.txt" 2>/dev/null
fi

ps aux > "$FOLDERRESULT/process-list.txt" 2>/dev/null
ps -eo user,pid,ppid,cmd > "$FOLDERRESULT/process-detailed.txt" 2>/dev/null

if command -v lsmod >/dev/null 2>&1; then
    lsmod > "$FOLDERRESULT/loaded-modules.txt" 2>/dev/null
fi

if command -v dpkg >/dev/null 2>&1; then
    dpkg -l > "$FOLDERRESULT/installed-packages.txt" 2>/dev/null
elif command -v rpm >/dev/null 2>&1; then
    rpm -qa > "$FOLDERRESULT/installed-packages.txt" 2>/dev/null
else
    echo "Package manager not supported" > "$FOLDERRESULT/installed-packages.txt"
fi

if command -v getent >/dev/null 2>&1; then
    getent passwd | cut -d: -f1 > "$FOLDERRESULT/users.txt" 2>/dev/null
else
    echo "Command 'getent' not found. Unable to collect users." > "$FOLDERRESULT/users.txt"
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl list-unit-files --type=service > "$FOLDERRESULT/services.txt" 2>/dev/null
    systemctl list-timers --all > "$FOLDERRESULT/scheduled-timers.txt" 2>/dev/null
fi

crontab -l > "$FOLDERRESULT/crontab.txt" 2>/dev/null

if command -v journalctl >/dev/null 2>&1; then
    journalctl -n 1000 > "$FOLDERRESULT/journal-logs.txt" 2>/dev/null
fi

if command -v uname >/dev/null 2>&1; then
    uname -a > "$FOLDERRESULT/kernel-info.txt" 2>/dev/null
fi

echo "Hashing..."
sha256sum "$FOLDERRESULT"/* > "$FOLDERRESULT/hashes.txt" 2>/dev/null

if [ -n "$OUTPUT_OWNER" ] && [ -n "$OUTPUT_GROUP" ]; then
    chown -R "$OUTPUT_OWNER:$OUTPUT_GROUP" "$FOLDERRESULT" 2>/dev/null
fi

echo "Terminated. Results saved in $FOLDERRESULT"
