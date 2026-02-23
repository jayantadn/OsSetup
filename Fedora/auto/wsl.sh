#!/bin/bash

echo "Running WSL-specific setup..."

# install thunar filemanager
if ! sudo dnf install -y thunar file-roller p7zip p7zip-plugins xfce4-terminal xterm; then
    track_failure "Thunar and file manager tools installation"
fi

# install other GUI tools
sudo dnf install -y gedit || track_failure "Gedit installation"
