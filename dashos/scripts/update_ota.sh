#!/bin/bash
# DashOS OTA Update Script
# Pulls latest code from GitHub and restarts the service

set -e

DASHOS_DIR="/opt/dashos"
REPO_URL="$(grep ota_repo $DASHOS_DIR/config/dashos.conf 2>/dev/null | cut -d= -f2)"
BRANCH="$(grep ota_branch $DASHOS_DIR/config/dashos.conf 2>/dev/null | cut -d= -f2)"

REPO_URL="${REPO_URL:-https://github.com/your-username/DashOS.git}"
BRANCH="${BRANCH:-main}"

echo "[DashOS OTA] Checking for updates..."
echo "  Repo: $REPO_URL"
echo "  Branch: $BRANCH"

cd "$DASHOS_DIR"

# Initialize git if needed
if [ ! -d .git ]; then
    echo "[DashOS OTA] First-time setup — cloning repo..."
    cd /opt
    rm -rf dashos_new
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" dashos_new/dashos
    # Preserve local config
    cp dashos/config/dashos.conf dashos_new/dashos/config/ 2>/dev/null || true
    mv dashos dashos_old
    mv dashos_new/dashos dashos
    rm -rf dashos_new dashos_old
else
    # Pull latest changes
    echo "[DashOS OTA] Pulling latest changes..."
    git fetch origin "$BRANCH"
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse "origin/$BRANCH")

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "[DashOS OTA] Already up to date!"
        exit 0
    fi

    git pull origin "$BRANCH"
fi

# Update Python dependencies
echo "[DashOS OTA] Updating dependencies..."
pip3 install --break-system-packages -r requirements.txt 2>/dev/null || \
pip3 install -r requirements.txt

# Restart service
echo "[DashOS OTA] Restarting DashOS..."
systemctl restart cage-dashos 2>/dev/null || \
systemctl restart dashos 2>/dev/null || true

echo "[DashOS OTA] Update complete!"
