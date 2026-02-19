#!/bin/bash
# DashOS Desktop — Linux/macOS Launcher

echo "==================================="
echo " DashOS Desktop - Vehicle Dashboard"
echo "==================================="
echo

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check Python
if ! command -v python3 &>/dev/null; then
    echo "ERROR: Python 3 not found. Install Python 3.8+"
    exit 1
fi

# Install dependencies if needed
if ! python3 -c "import PySide6" 2>/dev/null; then
    echo "Installing dependencies..."
    pip3 install -r "$SCRIPT_DIR/requirements.txt"
    echo
fi

# Launch with arguments passed through
python3 "$SCRIPT_DIR/main.py" "$@"
