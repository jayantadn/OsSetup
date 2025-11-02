#!/bin/sh

# Google drive
sudo apt install rclone -y
rclone config # give name as GoogleDrive and rest keep default
mkdir -p ~/GoogleDrive ~/.config/systemd/user
cat > ~/.config/systemd/user/rclone-gdrive.service <<'EOF'
[Unit]
Description=Rclone Mount Google Drive
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount GoogleDrive: %h/GoogleDrive \
  --vfs-cache-mode writes \
  --dir-cache-time 12h \
  --poll-interval 15s \
  --umask 022
ExecStop=/bin/fusermount -u %h/GoogleDrive
Restart=on-failure

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now rclone-gdrive.service
