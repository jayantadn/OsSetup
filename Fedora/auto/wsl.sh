#!/bin/bash

echo "Running WSL-specific setup..."

# install thunar filemanager
pkg_install_mapped thunar file-roller p7zip-full xfce4-terminal xterm

# install other GUI tools
pkg_install gedit
