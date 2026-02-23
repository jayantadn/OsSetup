#!/bin/bash

echo "Running WSL-specific setup..."

# install thunar filemanager
if ! sudo apt install -y thunar thunar-archive-plugin file-roller zip unzip p7zip-full rar unrar xfce4-terminal xterm; then
    track_failure "Thunar and file manager tools installation"
fi

# install other GUI tools
sudo apt install -y gedit || track_failure "Gedit installation"
