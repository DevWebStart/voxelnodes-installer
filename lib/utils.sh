#!/bin/bash

LOG_FILE="/tmp/voxelnodes.log"

run_cmd() {
    eval "$1" >> $LOG_FILE 2>&1

    if [ $? -ne 0 ]; then
        echo ""
        echo "✖ Installation failed"
        echo "Check logs: $LOG_FILE"
        exit 1
    fi
}

confirm() {
    read -p "Proceed? (y/n): " choice
    [[ "$choice" != "y" && "$choice" != "Y" ]] && exit 1
}
