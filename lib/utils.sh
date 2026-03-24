#!/bin/bash

run() {
    MSG=$1
    CMD=$2

    echo -ne "➤ $MSG..."

    bash -c "$CMD" >> /tmp/voxel_install.log 2>&1

    if [ $? -eq 0 ]; then
        echo -e "\r✔ $MSG"
    else
        echo -e "\r✖ FAILED: $MSG"
        echo "Check log: /tmp/voxel_install.log"
        exit 1
    fi
}
