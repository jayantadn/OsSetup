#!/bin/bash
set -e

# === SETTINGS ===
MOUNT_POINT="/media/GoogleDrive"
RCLONE_REMOTE_NAME="GoogleDrive"

# === STEP 1: Install rclone ===
echo "[*] Installing rclone..."
sudo apt update -y
sudo apt install -y rclone

# === STEP 2: Configure rclone if needed ===
if ! rclone listremotes | grep -q "^${RCLONE_REMOTE_NAME}:"; then
  echo
  echo "[*] rclone remote '${RCLONE_REMOTE_NAME}' not found. Launching setup..."
  echo "    - When prompted, name it '${RCLONE_REMOTE_NAME}'"
  echo "    - Choose 'drive' as the storage type"
  echo "    - Accept defaults unless you need advanced config"
  echo
  rclone config
fi

# === STEP 3: Create mount directory ===
echo "[*] Preparing mount point: ${MOUNT_POINT}"
sudo mkdir -p "$MOUNT_POINT"
sudo chown "$USER:$USER" "$MOUNT_POINT"

# === STEP 4: Ensure FUSE allows non-root mounts ===
if ! grep -q '^user_allow_other' /etc/fuse.conf 2>/dev/null; then
  echo "[*] Enabling 'user_allow_other' in /etc/fuse.conf..."
  echo "user_allow_other" | sudo tee -a /etc/fuse.conf >/dev/null
fi

# === STEP 5: Create systemd user service ===
echo "[*] Creating systemd user service..."

mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/rclone-gdrive.service <<EOF
[Unit]
Description=Rclone Mount Google Drive
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount ${RCLONE_REMOTE_NAME}: ${MOUNT_POINT} \\
  --vfs-cache-mode writes \\
  --dir-cache-time 12h \\
  --poll-interval 15s \\
  --umask 022 \\
  --allow-other
ExecStop=/bin/fusermount -u ${MOUNT_POINT}
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# === STEP 6: Enable and start the service ===
echo "[*] Enabling and starting rclone mount service..."
systemctl --user daemon-reload
systemctl --user enable --now rclone-gdrive.service

echo
echo "✅ Google Drive successfully mounted at: ${MOUNT_POINT}"
echo "✅ It will auto-mount whenever you log in."
echo
echo "To check status: systemctl --user status rclone-gdrive"
echo "To stop:         systemctl --user stop rclone-gdrive"
echo "To disable:      systemctl --user disable rclone-gdrive"

