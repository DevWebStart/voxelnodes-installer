#!/bin/bash

clear
echo "🚀 VoxelNodes Installer Loader"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Temp directory
INSTALL_DIR="/tmp/voxelnodes-installer"

echo "📥 Downloading installer..."

rm -rf $INSTALL_DIR

git clone https://github.com/DevWebS/voxelnodes-installer.git $INSTALL_DIR > /dev/null 2>&1

if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ Failed to download installer"
    exit 1
fi

cd $INSTALL_DIR

chmod +x installer.sh
chmod +x lib/*.sh
chmod +x modules/*.sh

echo "⚙️ Starting installer..."
echo ""

./installer.sh
