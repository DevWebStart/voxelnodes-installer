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
rm -rf installer.zip

# Download ZIP
curl -L -o installer.zip https://github.com/DevWebStart/voxelnodes-installer/archive/refs/heads/main.zip > /dev/null 2>&1

if [ ! -f "installer.zip" ]; then
    echo "❌ Download failed"
    exit 1
fi

# Ensure unzip exists
apt install unzip -y > /dev/null 2>&1

unzip installer.zip > /dev/null 2>&1

# 🔥 AUTO-DETECT FOLDER
EXTRACTED_DIR=$(ls -d */ | grep voxelnodes | head -n 1)

if [ -z "$EXTRACTED_DIR" ]; then
    echo "❌ Extraction failed"
    exit 1
fi

mv "$EXTRACTED_DIR" $INSTALL_DIR

cd $INSTALL_DIR

chmod +x installer.sh
chmod +x lib/*.sh
chmod +x modules/*.sh

echo "⚙️ Starting installer..."
echo ""

./installer.sh
