#!/bin/bash
# Configure DashOS for kiosk auto-start using cage compositor
# Cage runs a single Wayland app fullscreen — perfect for DashOS

set -e

echo "[DashOS] Setting up kiosk auto-start..."

# Install cage (minimal Wayland compositor)
apt-get install -y -qq cage

# Create cage auto-start service
cat > /etc/systemd/system/cage-dashos.service << 'EOF'
[Unit]
Description=DashOS Kiosk (Cage Wayland)
After=systemd-logind.service
Wants=systemd-logind.service

[Service]
Type=simple
User=pi
Environment=WLR_LIBINPUT_NO_DEVICES=1
Environment=XDG_RUNTIME_DIR=/run/user/1000
PAMName=login
TTYPath=/dev/tty7
ExecStartPre=/bin/mkdir -p /run/user/1000
ExecStartPre=/bin/chown pi:pi /run/user/1000
ExecStart=/usr/bin/cage -- /usr/bin/python3 /opt/dashos/main.py --fullscreen
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Disable default desktop (if any)
systemctl disable lightdm 2>/dev/null || true
systemctl disable gdm3 2>/dev/null || true

# Enable cage-dashos
systemctl daemon-reload
systemctl enable cage-dashos.service

# Configure Plymouth boot splash
if command -v plymouth &> /dev/null; then
    echo "[DashOS] Configuring boot splash..."
    # Use text theme as base (fastest)
    plymouth-set-default-theme -R text 2>/dev/null || true
fi

# Optimize boot speed
echo "[DashOS] Optimizing boot speed..."

# Disable unnecessary services
for svc in apt-daily apt-daily-upgrade avahi-daemon cups ModemManager; do
    systemctl disable "$svc" 2>/dev/null || true
    systemctl mask "$svc" 2>/dev/null || true
done

# Enable zram (better than swap for SD card)
if ! grep -q zram /etc/modules 2>/dev/null; then
    echo "zram" >> /etc/modules
fi

echo ""
echo "[DashOS] Kiosk auto-start configured!"
echo "  Reboot to start DashOS automatically."
echo "  To disable: systemctl disable cage-dashos"
