#!/bin/bash

# Source package manager abstraction
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../auto/pkg_manager.sh"

####################################################
# install docker
####################################################
if ! command -v docker &>/dev/null; then
    echo "[*] Installing Docker..."

    # Remove any legacy packages (ignore errors if not present)
    pkg_remove docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Prerequisites
    pkg_update
    pkg_install_mapped ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key and repository
    if [ "$PKG_MANAGER" = "apt" ]; then
        if [ ! -d /etc/apt/keyrings ]; then
            sudo install -m 0755 -d /etc/apt/keyrings
        fi
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Add the repository
        UBUNTU_CODENAME="$(get_codename)"
        ARCH="$(get_arch)"
        echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
            | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker Engine and related components
        pkg_update
        pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    # Enable and start Docker
    sudo systemctl enable --now docker

    # Add current user to docker group (requires re-login to take effect)
    sudo usermod -aG docker "$USER"

    # Simple verification (will pull hello-world image)
    echo "[*] Verifying Docker installation..."
    sudo docker run --rm hello-world || echo "[!] Docker verification step failed; check service status."

    echo "[*] Docker installation complete. Log out and back in (or run: newgrp docker) to use Docker without sudo."
else
    echo "[*] Docker already installed. Skipping Docker installation."
fi
