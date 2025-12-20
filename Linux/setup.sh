#!/bin/bash

## Store the current directory at the beginning
ROOTDIR="$(pwd)"

## Detect if running on WSL or native Ubuntu
if grep -qi microsoft /proc/version; then
    ubuntu_env="wsl"
    echo "Detected WSL environment."
else
    ubuntu_env="native"
    echo "Detected native Ubuntu environment."
fi

## Common for WSL and native
cd "$ROOTDIR" || exit
source "$ROOTDIR/auto/common.sh"

## WSL specific
if [ "$ubuntu_env" = "wsl" ]; then
    cd "$ROOTDIR" || exit
    source "$ROOTDIR/auto/wsl.sh"
fi

## Native Ubuntu specific
if [ "$ubuntu_env" = "native" ]; then
    cd "$ROOTDIR" || exit
    source "$ROOTDIR/auto/native.sh"
fi
