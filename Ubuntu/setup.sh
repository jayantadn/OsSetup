#!/bin/bash

## Store the current directory at the beginning
ROOTDIR="$(pwd)"

## Source package manager abstraction layer
cd "$ROOTDIR" || exit
source "$ROOTDIR/auto/pkg_manager.sh"

## Detect if running on WSL or native Linux
if grep -qi microsoft /proc/version; then
    linux_env="wsl"
    echo "Detected WSL environment."
else
    linux_env="native"
    echo "Detected native Linux environment."
fi

## Common for WSL and native
cd "$ROOTDIR" || exit
source "$ROOTDIR/auto/common.sh"

## WSL specific
if [ "$linux_env" = "wsl" ]; then
    cd "$ROOTDIR" || exit
    source "$ROOTDIR/auto/wsl.sh"
fi

## Native Linux specific
if [ "$linux_env" = "native" ]; then
    cd "$ROOTDIR" || exit
    source "$ROOTDIR/auto/native.sh"
fi
