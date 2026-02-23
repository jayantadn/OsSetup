#!/bin/bash

####################################################
# install docker
####################################################
if ! command -v docker &>/dev/null; then
    echo "[*] Installing Docker..."

    # Remove any legacy packages (ignore errors if not present)
    sudo dnf remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Prerequisites
    sudo dnf check-update || true
    sudo dnf install -y ca-certificates curl gnupg2 redhat-lsb-core

    # Add Docker's official GPG key and repository
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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
