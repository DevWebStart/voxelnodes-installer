#!/bin/bash

source lib/ui.sh
source lib/utils.sh

check_root
detect_os

show_banner

while true; do
    echo ""
    echo "1) Install Panel"
    echo "2) Install Wings"
    echo "3) Install Both"
    echo "4) Install Blueprint"
    echo "5) Install Themes/Addons"
    echo "6) Uninstall"
    echo "0) Exit"
    echo ""

    read -p "Select an option: " choice

    case $choice in
        1) bash modules/panel.sh "$1" ;;
        2) echo "Coming soon" ;;
        3) echo "Coming soon" ;;
        4) echo "Coming soon" ;;
        5) echo "Coming soon" ;;
        6) echo "Coming soon" ;;
        0) exit ;;
        *) echo "Invalid option" ;;
    esac
done
