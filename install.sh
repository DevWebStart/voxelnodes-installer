VERSION="1.0.0"
echo "Version: $VERSION"

#!/bin/bash

clear
echo "🚀 VoxelNodes Installer"
echo ""

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

echo "📡 Fetching installer..."

# Direct run (NO ZIP, NO CLONE)
bash <(curl -s https://raw.githubusercontent.com/DevWebStart/voxelnodes-installer/main/installer.sh)
