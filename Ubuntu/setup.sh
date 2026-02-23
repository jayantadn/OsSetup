#!/bin/bash

## Initialize failed installations tracking
declare -a FAILED_INSTALLATIONS=()

## Function to track failed installations
track_failure() {
    local step_name="$1"
    FAILED_INSTALLATIONS+=("$step_name")
}

## Function to print failed installations summary
print_failure_summary() {
    echo ""
    echo "=============================================="
    echo "         INSTALLATION SUMMARY"
    echo "=============================================="
    if [ ${#FAILED_INSTALLATIONS[@]} -eq 0 ]; then
        echo "✓ All installations completed successfully!"
    else
        echo "⚠ The following installations failed:"
        echo ""
        for failure in "${FAILED_INSTALLATIONS[@]}"; do
            echo "  ✗ $failure"
        done
        echo ""
        echo "Total failures: ${#FAILED_INSTALLATIONS[@]}"
    fi
    echo "=============================================="
}

## Set trap to print summary on exit
trap print_failure_summary EXIT

## Prompt for sudo access at the beginning
echo "This script requires sudo privileges. Please enter your password:"
sudo -v

## Keep sudo alive in the background
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

## Store the current directory at the beginning
ROOTDIR="$(pwd)"

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
