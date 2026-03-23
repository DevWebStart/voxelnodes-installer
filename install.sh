#!/bin/bash

echo "Downloading VoxelNodes Installer..."

# Clone repo
git clone https://github.com/YOUR_USERNAME/voxelnodes-installer.git

cd voxelnodes-installer

chmod +x installer.sh
chmod +x lib/*.sh
chmod +x modules/*.sh

# Run installer
./installer.sh
