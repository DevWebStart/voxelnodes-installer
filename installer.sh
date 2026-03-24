#!/bin/bash

source lib/ui.sh
source lib/utils.sh
source modules/panel.sh

check_root
detect_os

while true; do
    show_banner

    echo "1) Install Panel"
    echo "0) Exit"
    echo ""

    read -p "Select option: " opt

    case $opt in
        1)
            install_panel
            ;;
        0)
            exit
            ;;
        *)
            echo "Invalid"
            sleep 1
            ;;
    esac
done
