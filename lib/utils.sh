#!/bin/bash

LOG_FILE="/tmp/voxelnodes.log"

run_step() {
    local msg=$1
    local cmd=$2

    echo "➤ $msg..."

    eval "$cmd" >> $LOG_FILE 2>&1

    if [ $? -ne 0 ]; then
        echo "⚠️ Retry: $msg"
        sleep 2
        eval "$cmd" >> $LOG_FILE 2>&1

        if [ $? -ne 0 ]; then
            echo "❌ Failed: $msg"
            echo "Check logs: $LOG_FILE"
            exit 1
        fi
    fi

    echo "✔ $msg"
}

confirm() {
    read -p "Proceed? (y/n): " choice
    [[ "$choice" != "y" && "$choice" != "Y" ]] && exit 1
}
