#!/bin/bash

####################################################
# install docker
####################################################
if ! command -v docker &>/dev/null; then
    echo "[*] Installing Docker..."

    # Remove any legacy packages (ignore errors if not present)
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Prerequisites
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    if [ ! -d /etc/apt/keyrings ]; then
        sudo install -m 0755 -d /etc/apt/keyrings
    fi
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository (overwrite to ensure correctness)
    UBUNTU_CODENAME="$(lsb_release -cs)"
    ARCH="$(dpkg --print-architecture)"
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine and related components
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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
