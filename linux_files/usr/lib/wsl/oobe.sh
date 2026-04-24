#!/bin/bash

set -ue

POWERSHELL_PATH=$(wslpath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe')
LANGUAGE_HOST=$($POWERSHELL_PATH -Command '(Get-Culture).Name' | tr -d '\r\n' | tr '-' '_')
echo "Configuring locale for: ${LANGUAGE_HOST:-en_US}.UTF-8"
sed -i "s|^#[[:space:]]*\(en_US.UTF-8 UTF-8\).*|\1|g" /etc/locale.gen
sed -i "s|^#[[:space:]]*\(${LANGUAGE_HOST:-en_US}.UTF-8 UTF-8\).*|\1|g" /etc/locale.gen
locale-gen
localectl set-locale LANG=${LANGUAGE_HOST:-en_US}}.UTF-8
export LANG=$(grep '^LANG=' /etc/locale.conf | cut -d'=' -f2)

echo "Initializing pacman keyring..."
pacman-key --init
pacman-key --populate archlinux cachyos alhp
clear

DEFAULT_GROUPS=sys,network,rfkill,users,video,storage,lp,audio,wheel
DEFAULT_UID='1000'

echo 'Please create a default UNIX user account. The username does not need to match your Windows username.'
echo 'For more information visit: https://aka.ms/wslusers'

if getent passwd "$DEFAULT_UID" >/dev/null; then
    echo 'User account already exists, skipping creation'
    exit 0
fi

while true; do
    # Prompt from the username
    read -p 'Enter new UNIX username: ' username

    # Create the user
    if useradd --groups "$DEFAULT_GROUPS" --create-home --uid "$DEFAULT_UID" "$username"; then
        passwd "$username" && break || userdel --force --remove "$username" 2>/dev/null || true
    fi
done
