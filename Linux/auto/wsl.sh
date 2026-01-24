#!/bin/bash

echo "Running WSL-specific setup..."

# install thunar filemanager
pkg_install_mapped thunar thunar-archive-plugin file-roller zip unzip p7zip-full rar unrar xfce4-terminal xterm

# install other GUI tools
pkg_install gedit
