#!/bin/bash
# DashOS Installation Script for Raspberry Pi
# Run: sudo bash install.sh

set -e

echo "============================================"
echo "  DashOS Installer v1.0"
echo "  Vehicle Operating System for Raspberry Pi"
echo "============================================"
echo ""

# Check if running on Pi
if ! grep -q "Raspberry\|aarch64" /proc/cpuinfo 2>/dev/null && ! uname -m | grep -q "aarch64"; then
    echo "[WARN] Not running on Raspberry Pi. Some features may not work."
fi

# Update system
echo "[1/8] Updating system packages..."
apt-get update -qq

# Install system dependencies
echo "[2/8] Installing system dependencies..."
apt-get install -y -qq \
    python3 python3-pip python3-venv \
    qt6-base-dev qt6-declarative-dev \
    libqt6quick6 qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    bluetooth bluez pulseaudio-module-bluetooth \
    cage weston \
    plymouth \
    git curl wget

# Install Python packages
echo "[3/8] Installing Python packages..."
cd "$(dirname "$0")/.."
pip3 install --break-system-packages -r requirements.txt 2>/dev/null || \
pip3 install -r requirements.txt

# Set up Meshtastic daemon
echo "[4/8] Setting up Meshtastic daemon..."
pip3 install --break-system-packages meshtastic 2>/dev/null || \
pip3 install meshtastic

# Configure Bluetooth A2DP
echo "[5/8] Configuring Bluetooth audio..."
if [ -f /etc/bluetooth/main.conf ]; then
    sed -i 's/#Name = .*/Name = DashOS/' /etc/bluetooth/main.conf
    sed -i 's/#Class = .*/Class = 0x200414/' /etc/bluetooth/main.conf
    systemctl restart bluetooth 2>/dev/null || true
fi

# Set up DashOS systemd service
echo "[6/8] Creating DashOS service..."
cat > /etc/systemd/system/dashos.service << 'EOF'
[Unit]
Description=DashOS Vehicle Operating System
After=network.target bluetooth.target
Wants=bluetooth.target

[Service]
Type=simple
User=pi
Environment=QT_QPA_PLATFORM=wayland
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStart=/usr/bin/python3 /opt/dashos/main.py --fullscreen
WorkingDirectory=/opt/dashos
Restart=always
RestartSec=3

[Install]
WantedBy=graphical.target
EOF

# Copy DashOS to /opt
echo "[7/8] Installing DashOS application..."
mkdir -p /opt/dashos
cp -r . /opt/dashos/
chown -R pi:pi /opt/dashos

# Enable service
echo "[8/8] Enabling DashOS service..."
systemctl daemon-reload
systemctl enable dashos.service

echo ""
echo "============================================"
echo "  DashOS installed successfully!"
echo ""
echo "  Start manually:  systemctl start dashos"
echo "  View logs:       journalctl -u dashos -f"
echo "  Auto-start:      enabled on boot"
echo "============================================"
