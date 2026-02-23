#!/bin/bash

####################################################
# Package Manager Abstraction Layer
# Supports Ubuntu/Debian (apt) and Fedora/RHEL (dnf)
####################################################

# Detect the OS distribution
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
        OS_VERSION=$VERSION_ID
    else
        echo "Error: Cannot detect OS. /etc/os-release not found."
        exit 1
    fi

    case "$OS_ID" in
        ubuntu|debian)
            PKG_MANAGER="apt"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            PKG_MANAGER="dnf"
            ;;
        *)
            echo "Error: Unsupported OS: $OS_ID"
            echo "Supported distributions: Ubuntu, Debian, Fedora, RHEL, CentOS, Rocky, AlmaLinux"
            exit 1
            ;;
    esac

    echo "Detected OS: $OS_ID (Package Manager: $PKG_MANAGER)"
}

# Update package cache
pkg_update() {
    case "$PKG_MANAGER" in
        apt)
            sudo apt update
            ;;
        dnf)
            sudo dnf check-update || true
            ;;
    esac
}

# Upgrade all packages
pkg_upgrade() {
    case "$PKG_MANAGER" in
        apt)
            sudo apt upgrade -y
            ;;
        dnf)
            sudo dnf upgrade -y
            ;;
    esac
}

# Update and upgrade in one command
pkg_update_upgrade() {
    case "$PKG_MANAGER" in
        apt)
            sudo apt update && sudo apt upgrade -y
            ;;
        dnf)
            sudo dnf upgrade -y
            ;;
    esac
}

# Install packages
pkg_install() {
    local packages="$@"
    case "$PKG_MANAGER" in
        apt)
            sudo apt install -y $packages
            ;;
        dnf)
            sudo dnf install -y $packages
            ;;
    esac
}

# Remove packages
pkg_remove() {
    local packages="$@"
    case "$PKG_MANAGER" in
        apt)
            sudo apt remove -y $packages
            ;;
        dnf)
            sudo dnf remove -y $packages
            ;;
    esac
}

# Auto-remove unused packages
pkg_autoremove() {
    case "$PKG_MANAGER" in
        apt)
            sudo apt autoremove -y
            ;;
        dnf)
            sudo dnf autoremove -y
            ;;
    esac
}

# Install a local package file
pkg_install_local() {
    local package_file="$1"
    case "$PKG_MANAGER" in
        apt)
            sudo apt install -y "$package_file"
            ;;
        dnf)
            sudo dnf install -y "$package_file"
            ;;
    esac
}

# Fix broken dependencies
pkg_fix_dependencies() {
    case "$PKG_MANAGER" in
        apt)
            sudo apt install -f -y
            ;;
        dnf)
            sudo dnf install -y --best --allowerasing
            ;;
    esac
}

# Add a repository
pkg_add_repo() {
    local repo_info="$1"
    case "$PKG_MANAGER" in
        apt)
            # For apt, repo_info should be the full line for sources.list
            echo "$repo_info" | sudo tee /etc/apt/sources.list.d/custom.list > /dev/null
            sudo apt update
            ;;
        dnf)
            # For dnf, repo_info should be the repo URL or file
            sudo dnf config-manager --add-repo "$repo_info"
            ;;
    esac
}

# Get architecture
get_arch() {
    case "$PKG_MANAGER" in
        apt)
            dpkg --print-architecture
            ;;
        dnf)
            uname -m
            ;;
    esac
}

# Get codename (for Ubuntu) or version (for Fedora)
get_codename() {
    case "$PKG_MANAGER" in
        apt)
            lsb_release -cs
            ;;
        dnf)
            echo "$OS_VERSION"
            ;;
    esac
}

# Map common package names between distributions
map_package_name() {
    local pkg="$1"
    
    # Common package name mappings (Ubuntu -> Fedora)
    case "$PKG_MANAGER" in
        dnf)
            case "$pkg" in
                build-essential)
                    echo "gcc gcc-c++ make"
                    ;;
                software-properties-common)
                    echo "dnf-plugins-core"
                    ;;
                apt-transport-https)
                    echo ""  # Not needed in Fedora
                    ;;
                gnupg)
                    echo "gnupg2"
                    ;;
                libbz2-dev)
                    echo "bzip2-devel"
                    ;;
                libreadline-dev)
                    echo "readline-devel"
                    ;;
                libsqlite3-dev)
                    echo "sqlite-devel"
                    ;;
                libncursesw5-dev)
                    echo "ncurses-devel"
                    ;;
                tk-dev)
                    echo "tk-devel"
                    ;;
                libxml2-dev)
                    echo "libxml2-devel"
                    ;;
                libxmlsec1-dev)
                    echo "xmlsec1-devel"
                    ;;
                libffi-dev)
                    echo "libffi-devel"
                    ;;
                liblzma-dev)
                    echo "xz-devel"
                    ;;
                libssl-dev)
                    echo "openssl-devel"
                    ;;
                zlib1g-dev)
                    echo "zlib-devel"
                    ;;
                android-tools-adb)
                    echo "android-tools"
                    ;;
                android-tools-fastboot)
                    echo ""  # Included in android-tools
                    ;;
                lsb-release)
                    echo "redhat-lsb-core"
                    ;;
                qemu-kvm)
                    echo "qemu-kvm"
                    ;;
                libvirt-daemon-system)
                    echo "libvirt-daemon"
                    ;;
                libvirt-clients)
                    echo "libvirt-client"
                    ;;
                bridge-utils)
                    echo "bridge-utils"
                    ;;
                virtinst)
                    echo "virt-install"
                    ;;
                virt-manager)
                    echo "virt-manager"
                    ;;
                libreoffice)
                    echo "libreoffice"
                    ;;
                file-roller)
                    echo "file-roller"
                    ;;
                p7zip-full)
                    echo "p7zip p7zip-plugins"
                    ;;
                openjdk-17-jdk)
                    echo "java-17-openjdk java-17-openjdk-devel"
                    ;;
                *)
                    echo "$pkg"
                    ;;
            esac
            ;;
        apt)
            echo "$pkg"
            ;;
    esac
}

# Install packages with automatic name mapping
pkg_install_mapped() {
    local mapped_packages=""
    for pkg in "$@"; do
        local mapped=$(map_package_name "$pkg")
        if [ -n "$mapped" ]; then
            mapped_packages="$mapped_packages $mapped"
        fi
    done
    
    if [ -n "$mapped_packages" ]; then
        pkg_install $mapped_packages
    fi
}

# Initialize the package manager detection
detect_os

# Export functions and variables for use in other scripts
export PKG_MANAGER
export OS_ID
export OS_VERSION
export -f pkg_update
export -f pkg_upgrade
export -f pkg_update_upgrade
export -f pkg_install
export -f pkg_remove
export -f pkg_autoremove
export -f pkg_install_local
export -f pkg_fix_dependencies
export -f pkg_add_repo
export -f get_arch
export -f get_codename
export -f map_package_name
export -f pkg_install_mapped
