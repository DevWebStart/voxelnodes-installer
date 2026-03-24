#!/bin/bash

clear
echo "🚀 VoxelNodes Installer"
echo ""

INSTALL_DIR="/tmp/voxelnodes-installer"

echo "📡 Fetching installer..."

rm -rf $INSTALL_DIR
rm -rf installer.zip

# download zip
curl -L -o installer.zip https://github.com/DevWebStart/voxelnodes-installer/archive/refs/heads/main.zip > /dev/null 2>&1

if [ ! -f "installer.zip" ]; then
    echo "❌ Download failed"
    exit 1
fi

apt install unzip -y > /dev/null 2>&1
unzip installer.zip > /dev/null 2>&1

DIR=$(ls -d */ | grep voxelnodes | head -n 1)

mv "$DIR" "$INSTALL_DIR"
cd $INSTALL_DIR

chmod +x installer.sh
chmod +x lib/*.sh
chmod +x modules/*.sh

echo "⚙️ Launching installer..."
sleep 1

./installer.sh
