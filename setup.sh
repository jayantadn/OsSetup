#!/bin/bash

## Detect if running on WSL or native Ubuntu
if grep -qi microsoft /proc/version; then
    ubuntu_env="wsl"
    echo "Detected WSL environment."
else
    ubuntu_env="native"
    echo "Detected native Ubuntu environment."
fi

## Common for WSL and native
source common.sh

## WSL specific
if [ "$ubuntu_env" = "wsl" ]; then
    source wsl.sh
fi

## Native Ubuntu specific
if [ "$ubuntu_env" = "native" ]; then
    source native.sh
fi
