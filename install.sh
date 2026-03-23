#!/bin/bash

clear
echo "🚀 VoxelNodes Installer Loader"
echo ""

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

INSTALL_DIR="/tmp/voxelnodes-installer"

echo "📥 Downloading installer..."

rm -rf $INSTALL_DIR

# 🔥 FIX: force public clone (no auth)
git clone --depth=1 https://github.com/DevWebS/voxelnodes-installer.git $INSTALL_DIR 2>/dev/null

if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ Failed to download installer"
    echo "Make sure repo is public"
    exit 1
fi

cd $INSTALL_DIR

chmod +x installer.sh
chmod +x lib/*.sh
chmod +x modules/*.sh

echo "⚙️ Starting installer..."
echo ""

./installer.sh
