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

# insltall vscode
sudo apt install -y wget gpg apt-transport-https software-properties-common
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
| sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
sudo apt update
sudo apt install -y code

# detect android phone
sudo apt install -y android-tools-adb android-tools-fastboot

# media player
sudo apt install -y vlc

# docker
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker || true
sudo usermod -aG docker $USER

# kdiff3
sudo apt install -y kdiff3 dolphin-plugins
