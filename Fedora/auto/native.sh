#!/bin/bash

###########################
# install standard packages
###########################
sudo dnf update -y
sudo dnf install -y vlc kdiff3 dolphin libreoffice

###############
# timesync fix
###############
sudo timedatectl set-timezone Asia/Kolkata

###########################
# set grub timeout as 3s
###########################
GRUB_CFG_FILE="/etc/default/grub"
sudo cp "$GRUB_CFG_FILE" "${GRUB_CFG_FILE}.bak.$(date +%Y%m%d%H%M%S)"
if grep -q "^GRUB_TIMEOUT=" "$GRUB_CFG_FILE"; then
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' "$GRUB_CFG_FILE"
else
    echo "GRUB_TIMEOUT=3" | sudo tee -a "$GRUB_CFG_FILE" > /dev/null
fi
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# install vscode
pkg_install_mapped wget gpg software-properties-common
if [ "$PKG_MANAGER" = "apt" ]; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
| sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    pkg_update
    pkg_install code
elif [ "$PKG_MANAGER" = "dnf" ]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    pkg_install code
fi

# detect android phone
pkg_install_mapped android-tools-adb android-tools-fastboot

# media player
pkg_install vlc

# docker
pkg_remove docker docker-engine docker.io containerd runc || true
pkg_install_mapped ca-certificates curl gnupg lsb-release
if [ "$PKG_MANAGER" = "apt" ]; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(get_arch) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(get_codename) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    pkg_update
    pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
elif [ "$PKG_MANAGER" = "dnf" ]; then
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
fi
sudo groupadd docker || true
sudo usermod -aG docker $USER

# kdiff3
pkg_install kdiff3

# input remapper - for mouse button customization
###########################
REPO="sezanzeb/input-remapper"
WORKDIR="$(mktemp -d)"
cd "$WORKDIR"
for cmd in curl jq; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "Installing missing dependency: $cmd"
    pkg_update
    pkg_install "$cmd"
  fi
done
echo "Fetching latest release info for $REPO..."
release_json=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest")

# Try to find RPM for Fedora
if [ "$PKG_MANAGER" = "dnf" ]; then
    asset_url=$(echo "$release_json" | jq -r '.assets[] | select(.name | test("\\.rpm$")) | .browser_download_url' | head -n1)
    if [ -z "$asset_url" ] || [ "$asset_url" = "null" ]; then
        echo "No .rpm asset found, trying .deb (may need alien)..."
        asset_url=$(echo "$release_json" | jq -r '.assets[] | select(.name | test("\\.deb$")) | .browser_download_url' | head -n1)
        # Install alien if we need to convert deb to rpm
        if [ -n "$asset_url" ] && [ "$asset_url" != "null" ]; then
            pkg_install alien
        fi
    fi
else
    asset_url=$(echo "$release_json" | jq -r '.assets[] | select(.name | test("\\.deb$")) | .browser_download_url' | head -n1)
fi

if [ -z "$asset_url" ] || [ "$asset_url" = "null" ]; then
  echo "No package asset found in latest release. Skipping input-remapper installation."
else
    pkgname="$(basename "$asset_url")"
    echo "Downloading asset: $pkgname"
    curl -L -o "$pkgname" "$asset_url"
    echo "Installing $pkgname (may ask for sudo)..."
    
    if [[ "$pkgname" == *.rpm ]]; then
        if pkg_install_local "./$pkgname"; then
            echo "Package installed successfully."
        else
            echo "Package install failed; trying to fix dependencies..."
            pkg_fix_dependencies
            sudo rpm -i "./$pkgname" || echo "rpm install failed"
        fi
    elif [[ "$pkgname" == *.deb ]] && [ "$PKG_MANAGER" = "dnf" ]; then
        echo "Converting .deb to .rpm using alien..."
        sudo alien -r "$pkgname"
        rpmname="${pkgname%.deb}*.rpm"
        sudo rpm -i $rpmname || echo "rpm install failed"
    else
        if pkg_install_local "./$pkgname"; then
            echo "Package installed successfully."
        else
            echo "Package install failed; trying to fix dependencies..."
            pkg_fix_dependencies
            sudo dpkg -i "./$pkgname" || echo "dpkg failed"
        fi
    fi
    
    if systemctl list-unit-files --type=service 2>/dev/null | grep -q '^input-remapper'; then
      echo "Enabling and starting input-remapper service..."
      sudo systemctl enable --now input-remapper.service || echo "Could not enable/start input-remapper.service — check logs."
    else
      echo "No input-remapper service unit found (or systemd not present)."
    fi
fi
echo "Cleaning up $WORKDIR"
rm -rf "$WORKDIR"
echo "Done. Run 'input-remapper-gtk' or 'input-remapper-control --version' to verify."


# other packages
pkg_install_mapped libreoffice

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
    pkg_install "$cmd"
  fi
done
echo "Fetching latest release info for $REPO..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    # Try to find RPM for Fedora
    asset_url=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | \
      grep -o 'https://github.com/[^"]*Fedora[^"]*x86_64\.rpm' | head -n1)
    
    # If Fedora RPM not found, try generic RPM
    if [ -z "$asset_url" ]; then
        asset_url=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | \
          grep -o 'https://github.com/[^"]*\.rpm' | grep x86_64 | head -n1)
    fi
else
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
fi

if [ -z "$asset_url" ]; then
  echo "No suitable package asset found in latest release. Skipping CopyQ installation."
else
    pkgname="$(basename "$asset_url")"
    echo "Downloading asset: $pkgname"
    curl -L -o "$pkgname" "$asset_url"
    echo "Installing $pkgname (may ask for sudo)..."
    if pkg_install_local "./$pkgname"; then
      echo "Package installed successfully."
    else
      echo "Package install failed; trying to fix dependencies..."
      pkg_fix_dependencies
      if [[ "$pkgname" == *.rpm ]]; then
          sudo rpm -i "./$pkgname" || echo "rpm install failed"
      else
          sudo dpkg -i "./$pkgname" || echo "dpkg failed"
      fi
    fi
fi
echo "Cleaning up $WORKDIR"
rm -rf "$WORKDIR"
echo "Done. Run 'copyq' to launch CopyQ."
