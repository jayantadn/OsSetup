#!/bin/bash

# timesync fix
sudo timedatectl set-timezone Asia/Kolkata

# set grub timeout as 3s
GRUB_CFG_FILE="/etc/default/grub"
sudo cp "$GRUB_CFG_FILE" "${GRUB_CFG_FILE}.bak.$(date +%Y%m%d%H%M%S)"
if grep -q "^GRUB_TIMEOUT=" "$GRUB_CFG_FILE"; then
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' "$GRUB_CFG_FILE"
else
    echo "GRUB_TIMEOUT=3" | sudo tee -a "$GRUB_CFG_FILE" > /dev/null
fi
sudo update-grub

# install Joplin
wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash

# insltall vscode
sudo apt install -y wget gpg apt-transport-https software-properties-common
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
| sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
sudo apt update
sudo apt install -y code

# detect android phone
sudo apt install android-tools-adb android-tools-fastboot
