#!/bin/bash

echo "Running WSL-specific setup..."

# install thunar filemanager
sudo dnf install -y thunar file-roller p7zip p7zip-plugins xfce4-terminal xterm

# install other GUI tools
sudo dnf install -y gedit
