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

# input remapper - for mouse button customization
REPO="sezanzeb/input-remapper"
WORKDIR="$(mktemp -d)"
cd "$WORKDIR"
for cmd in curl jq; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "Installing missing dependency: $cmd"
    sudo apt update
    sudo apt install -y "$cmd"
  fi
done
echo "Fetching latest release info for $REPO..."
release_json=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest")
asset_url=$(echo "$release_json" | jq -r '.assets[] | select(.name | test("\\.deb$")) | .browser_download_url' | head -n1)
if [ -z "$asset_url" ] || [ "$asset_url" = "null" ]; then
  echo "No .deb asset found in latest release. Abort."
  exit 1
fi
debname="$(basename "$asset_url")"
echo "Downloading asset: $debname"
curl -L -o "$debname" "$asset_url"
echo "Installing $debname (may ask for sudo)..."
if sudo apt install -y "./$debname"; then
  echo "Package installed successfully via apt."
else
  echo "apt install failed; trying to fix dependencies..."
  sudo apt install -f -y
  sudo dpkg -i "./$debname" || { echo "dpkg failed"; exit 2; }
fi
if systemctl list-unit-files --type=service 2>/dev/null | grep -q '^input-remapper'; then
  echo "Enabling and starting input-remapper service..."
  sudo systemctl enable --now input-remapper.service || echo "Could not enable/start input-remapper.service — check logs."
else
  echo "No input-remapper service unit found (or systemd not present)."
fi
echo "Cleaning up $WORKDIR"
rm -rf "$WORKDIR"
echo "Done. Run 'input-remapper-gtk' or 'input-remapper-control --version' to verify."


# other packages
sudo apt install -y libreoffice

####################################
# CopyQ - clipboard manager
# https://github.com/hluk/CopyQ
####################################
REPO="hluk/CopyQ"
WORKDIR="$(mktemp -d)"
cd "$WORKDIR"
for cmd in curl; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "Installing missing dependency: $cmd"
    sudo apt install -y "$cmd"
  fi
done
echo "Fetching latest release info for $REPO..."
# Get the latest release data and extract .deb URL using grep
# Prefer Debian 13 package which should work on newer Ubuntu versions
asset_url=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | \
  grep -o 'https://github.com/[^"]*Debian_13[^"]*amd64\.deb' | head -n1)

# If Debian 13 not found, try Debian 12
if [ -z "$asset_url" ]; then
  asset_url=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | \
    grep -o 'https://github.com/[^"]*Debian_12[^"]*amd64\.deb' | head -n1)
fi

# If still not found, try any .deb file
if [ -z "$asset_url" ]; then
  asset_url=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | \
    grep -o 'https://github.com/[^"]*\.deb' | grep amd64 | head -n1)
fi

if [ -z "$asset_url" ]; then
  echo "No suitable .deb asset found in latest release. Abort."
  exit 1
fi
debname="$(basename "$asset_url")"
echo "Downloading asset: $debname"
curl -L -o "$debname" "$asset_url"
echo "Installing $debname (may ask for sudo)..."
if sudo apt install -y "./$debname"; then
  echo "Package installed successfully via apt."
else
  echo "apt install failed; trying to fix dependencies..."
  sudo apt install -f -y
  sudo dpkg -i "./$debname" || { echo "dpkg failed"; exit 2; }
fi
echo "Cleaning up $WORKDIR"
rm -rf "$WORKDIR"
echo "Done. Run 'copyq' to launch CopyQ."

