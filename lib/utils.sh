#!/bin/bash

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Run as root"
        exit
    fi
}

detect_os() {
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        echo "Only Ubuntu supported"
        exit
    fi
}
