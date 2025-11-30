#!/bin/bash

# initial steps
sudo apt update && sudo apt upgrade -y

# git configure
git config --global user.name "Jayanta Debnath"
git config --global user.email Jayanta.Dn@gmail.com

# add path
cp ~/.bashrc ~/.bashrc.orig
if ! grep -q "export PATH=.*\$HOME/Tools/flutter/bin" ~/.bashrc; then
    echo "export PATH=\$PATH:\$HOME/Tools/flutter/bin" >> ~/.bashrc
fi

# setup command prompt
if ! grep -q "export PS1=" ~/.bashrc; then
    echo "export PS1='\\[\\e[35m\\][\\A]\\[\\e[0m\\] \\[\\e[34m\\]\\W\\[\\e[0m\\] \\$ '" >> ~/.bashrc
fi

# install python
PYTHON_VERSION=3.10.13
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils \
tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
cd /usr/src
sudo wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
sudo tar xvf Python-${PYTHON_VERSION}.tgz
sudo rm Python-${PYTHON_VERSION}.tgz
cd Python-${PYTHON_VERSION}
sudo ./configure --enable-optimizations
sudo make -j"$(nproc)"
sudo make altinstall
cd /usr/src
sudo rm -rf Python-${PYTHON_VERSION}


# install android sdk
SDK_DIR="$HOME/Tools/android-sdk"
TOOLS_ZIP="commandlinetools-linux.zip"
SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
sudo apt install -y unzip curl openjdk-17-jdk
mkdir -p "$SDK_DIR/cmdline-tools"
curl -o "$TOOLS_ZIP" "$SDK_URL"
unzip -q "$TOOLS_ZIP" -d "$SDK_DIR/cmdline-tools"
mv "$SDK_DIR/cmdline-tools/cmdline-tools" "$SDK_DIR/cmdline-tools/latest"
rm "$TOOLS_ZIP"
if ! grep -q "ANDROID_HOME" "$HOME/.bashrc"; then
    echo "[*] Adding environment variables to ~/.bashrc"
    cat <<EOF >> "$HOME/.bashrc"

# Android SDK
export ANDROID_HOME="$SDK_DIR"
export PATH="\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
EOF
else
    echo "[*] Android environment variables already exist in ~/.bashrc"
fi
rm -rf "$ANDROID_HOME/cmdline-tools/latest"
mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
export ANDROID_HOME="$SDK_DIR"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
yes | sdkmanager --sdk_root="$SDK_DIR" --licenses
$HOME/Tools/android-sdk/cmdline-tools/cmdline-tools/bin/sdkmanager --sdk_root="$SDK_DIR" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
flutter doctor --android-licenses

# install node and firebase cli
sudo apt install -y curl software-properties-common
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash -
sudo apt install -y nodejs
sudo npm install -g firebase-tools
dart pub global activate flutterfire_cli

# install google chrome
sudo apt install -y wget curl apt-transport-https gnupg
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb
sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb
rm /tmp/google-chrome-stable_current_amd64.deb

# install qemu
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER
sudo systemctl enable --now libvirtd

# clone the Scripts repo
mkdir $HOME/GitRepos
git clone https://github.com/jayantadn/Scripts.git "$HOME/GitRepos/Scripts"
python3.10 -m venv $HOME/GitRepos/Scripts/.venv
source $HOME/GitRepos/Scripts/.venv/bin/activate
pip install -r $HOME/GitRepos/Scripts/requirements.txt
deactivate

# install docker
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

# install other common tools
sudo apt install -y vim
