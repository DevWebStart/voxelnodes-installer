#!/bin/bash

LOG_FILE="/var/log/voxelnodes-installer.log"
DRY_RUN=false

if [[ "$1" == "--test" ]]; then
    DRY_RUN=true
fi

touch $LOG_FILE

log() {
    echo "[INFO] $1" >> $LOG_FILE
}

error() {
    echo "[ERROR] $1" >> $LOG_FILE
}

success() {
    echo "[SUCCESS] $1" >> $LOG_FILE
}

confirm() {
    read -p "Proceed? (y/n): " choice
    [[ "$choice" != "y" && "$choice" != "Y" ]] && exit 1
}

run_cmd() {
    log "Running: $1"

    if [ "$DRY_RUN" = true ]; then
        return
    fi

    eval $1 >> $LOG_FILE 2>&1

    if [ $? -ne 0 ]; then
        error "Failed: $1"
        fail_msg
        exit 1
    fi
}

check_root() {
    [ "$DRY_RUN" = true ] && return

    if [ "$EUID" -ne 0 ]; then
        echo "Run as root"
        exit 1
    fi
}

detect_os() {
    . /etc/os-release
    log "OS: $ID $VERSION_ID"
}
