#!/bin/bash

# Detect if running on WSL or native Ubuntu
if grep -qi microsoft /proc/version; then
    ubuntu_env="wsl"
    echo "Detected WSL environment."
else
    ubuntu_env="native"
    echo "Detected native Ubuntu environment."
fi

# Common for WSL and native

# initial steps
sudo apt update && sudo apt upgrade -y

# setup command prompt
echo "export PS1='\\[\\e[35m\\][\\A]\\[\\e[0m\\] \\[\\e[34m\\]\\W\\[\\e[0m\\] \\$ '" >> ~/.bashrc

# install python 3.10
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
cd /usr/src
sudo wget https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz
sudo tar xvf Python-3.10.13.tgz
sudo rm Python-3.10.13.tgz
cd Python-3.10.13
sudo ./configure --enable-optimizations
sudo make -j$(nproc)
sudo make altinstall
sudo rm -rf /usr/src/Python-3.10.13

# WSL specific
if [ "$ubuntu_env" = "wsl" ]; then
    echo "Running WSL-specific setup..."
fi

# Native Ubuntu specific
if [ "$ubuntu_env" = "native" ]; then
    # install chrome
    mkdir -p ~/Downloads
    wget -O ~/Downloads/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i ~/Downloads/google-chrome-stable_current_amd64.deb
fi
fi
