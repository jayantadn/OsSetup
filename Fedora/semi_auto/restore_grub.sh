#!/bin/bash
set -e

# Source package manager abstraction
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../auto/pkg_manager.sh"

####################################################
# Restore GRUB as Default Bootloader
# Use this script after Windows installation overwrites the bootloader
####################################################

echo "================================================"
echo "  GRUB Bootloader Restoration Script"
echo "================================================"
echo

# Check if running with sudo/root
if [ "$EUID" -ne 0 ]; then
  echo "[!] This script requires root privileges."
  echo "    Please run with: sudo $0"
  exit 1
fi

# === STEP 1: Install os-prober (to detect Windows) ===
echo "[*] Step 1: Ensuring os-prober is installed..."
pkg_install os-prober
echo "    ✓ os-prober installed"
echo

# === STEP 2: Enable os-prober in GRUB config ===
echo "[*] Step 2: Enabling os-prober in GRUB configuration..."
GRUB_CONFIG="/etc/default/grub"

if ! grep -q "^GRUB_DISABLE_OS_PROBER=false" "$GRUB_CONFIG"; then
  # Check if the line exists but is commented or set to true
  if grep -q "^#*GRUB_DISABLE_OS_PROBER" "$GRUB_CONFIG"; then
    # Replace existing line
    sed -i 's/^#*GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$GRUB_CONFIG"
    echo "    ✓ Updated GRUB_DISABLE_OS_PROBER=false"
  else
    # Add new line
    echo "GRUB_DISABLE_OS_PROBER=false" >> "$GRUB_CONFIG"
    echo "    ✓ Added GRUB_DISABLE_OS_PROBER=false"
  fi
else
  echo "    ✓ os-prober already enabled"
fi
echo

# === STEP 3: Update GRUB to detect all operating systems ===
echo "[*] Step 3: Updating GRUB configuration..."
echo "    This will scan for Windows and other operating systems..."

# Fedora uses different commands for GRUB update
if [ "$PKG_MANAGER" = "dnf" ]; then
    # For UEFI systems
    if [ -d /sys/firmware/efi ]; then
        grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    else
        # For BIOS systems
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
else
    # Ubuntu/Debian
    update-grub
fi
echo

# === STEP 4: Replace Windows bootloader with GRUB ===
echo "[*] Step 4: Backing up Windows bootloader and replacing with GRUB..."
echo

# Find EFI partition mount point
EFI_MOUNT=$(findmnt -n -o TARGET -t vfat | grep -i efi | head -n 1)

if [ -z "$EFI_MOUNT" ]; then
  echo "[!] Could not find EFI partition mount point."
  echo "    Trying to mount EFI partition..."
  
  # Find EFI partition
  EFI_PART=$(lsblk -f | grep -i vfat | grep -i efi | awk '{print $1}' | head -n 1)
  if [ -z "$EFI_PART" ]; then
    EFI_PART=$(fdisk -l | grep -i "EFI System" | awk '{print $1}' | head -n 1)
  fi
  
  if [ -n "$EFI_PART" ]; then
    EFI_MOUNT="/boot/efi"
    mkdir -p "$EFI_MOUNT"
    mount "$EFI_PART" "$EFI_MOUNT"
    echo "    ✓ Mounted EFI partition at $EFI_MOUNT"
  else
    echo "[!] Error: Could not find EFI partition."
    echo "    Please mount your EFI partition manually and run this script again."
    exit 1
  fi
fi

echo "    EFI partition mounted at: $EFI_MOUNT"

# Paths
WINDOWS_BOOTMGR="$EFI_MOUNT/EFI/Microsoft/Boot/bootmgfw.efi"
WINDOWS_BACKUP="$EFI_MOUNT/EFI/Microsoft/Boot/bootmgfw.efi.backup"

# Find GRUB bootloader (Fedora uses different paths)
if [ "$PKG_MANAGER" = "dnf" ]; then
    # Fedora GRUB locations
    if [ -f "$EFI_MOUNT/EFI/fedora/shimx64.efi" ]; then
        GRUB_BOOTLOADER="$EFI_MOUNT/EFI/fedora/shimx64.efi"
    elif [ -f "$EFI_MOUNT/EFI/fedora/grubx64.efi" ]; then
        GRUB_BOOTLOADER="$EFI_MOUNT/EFI/fedora/grubx64.efi"
    fi
else
    # Ubuntu GRUB locations
    if [ -f "$EFI_MOUNT/EFI/ubuntu/shimx64.efi" ]; then
        GRUB_BOOTLOADER="$EFI_MOUNT/EFI/ubuntu/shimx64.efi"
    elif [ -f "$EFI_MOUNT/EFI/ubuntu/grubx64.efi" ]; then
        GRUB_BOOTLOADER="$EFI_MOUNT/EFI/ubuntu/grubx64.efi"
    fi
fi

# Check if files exist
if [ ! -f "$GRUB_BOOTLOADER" ]; then
    echo "[!] Error: Could not find GRUB bootloader"
    echo "    Available EFI files:"
    find "$EFI_MOUNT/EFI" -name "*.efi" 2>/dev/null
    exit 1
fi

echo "    Found GRUB bootloader: $GRUB_BOOTLOADER"

# Backup Windows bootloader if it exists and hasn't been backed up
if [ -f "$WINDOWS_BOOTMGR" ]; then
  if [ ! -f "$WINDOWS_BACKUP" ]; then
    echo "    Backing up Windows bootloader..."
    cp "$WINDOWS_BOOTMGR" "$WINDOWS_BACKUP"
    echo "    ✓ Windows bootloader backed up to: bootmgfw.efi.backup"
  else
    echo "    ✓ Windows bootloader already backed up"
  fi
  
  # Replace Windows bootloader with GRUB
  echo "    Replacing Windows bootloader with GRUB..."
  cp "$GRUB_BOOTLOADER" "$WINDOWS_BOOTMGR"
  echo "    ✓ GRUB copied to Windows bootloader location"
else
  echo "    Windows bootloader not found (this is OK if Windows isn't installed)"
  echo "    Creating Microsoft/Boot directory and copying GRUB..."
  mkdir -p "$EFI_MOUNT/EFI/Microsoft/Boot"
  cp "$GRUB_BOOTLOADER" "$WINDOWS_BOOTMGR"
  echo "    ✓ GRUB installed as Windows bootloader"
fi
echo

# === STEP 5: Verify changes ===
echo "[*] Step 5: Verifying configuration..."
echo
echo "Files in EFI/Microsoft/Boot:"
ls -lh "$EFI_MOUNT/EFI/Microsoft/Boot/" | grep -E "bootmgfw|backup"
echo

echo "================================================"
echo "  ✓ GRUB Restoration Complete!"
echo "================================================"
echo
echo "GRUB has been set as the default bootloader by replacing"
echo "the Windows Boot Manager with GRUB. Your UEFI firmware will"
echo "now boot GRUB by default."
echo
echo "When you reboot, you'll see the GRUB menu with options for:"
echo "  - Fedora/Ubuntu"
echo "  - Windows Boot Manager (if detected)"
echo
echo "The original Windows bootloader has been backed up to:"
echo "  $WINDOWS_BACKUP"
echo
echo "To restore Windows bootloader (if needed):"
echo "  sudo cp $WINDOWS_BACKUP $WINDOWS_BOOTMGR"
echo
