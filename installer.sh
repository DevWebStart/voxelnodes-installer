#!/bin/bash

source lib/ui.sh
source lib/utils.sh

while true; do
    show_banner
    echo -e "\e[92m1) Install Panel"
    echo "0) Exit\e[0m"
    echo ""
    read -p "Select option: " opt

    case $opt in
        1) bash modules/panel.sh ;;
        0) exit ;;
        *) echo "Invalid option"; sleep 1 ;;
    esac
done
