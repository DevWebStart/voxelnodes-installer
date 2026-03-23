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

# ✅ ZIP DOWNLOAD (NO LOGIN, NO GIT)
curl -L -o installer.zip https://github.com/DevWebStart/voxelnodes-installer/archive/refs/heads/main.zip > /dev/null 2>&1

if [ ! -f "installer.zip" ]; then
    echo "❌ Failed to download installer"
    exit 1
fi

unzip installer.zip > /dev/null 2>&1

mv voxelnodes-installer-main $INSTALL_DIR

cd $INSTALL_DIR

chmod +x installer.sh
chmod +x lib/*.sh
chmod +x modules/*.sh

echo "⚙️ Starting installer..."
echo ""

./installer.sh
