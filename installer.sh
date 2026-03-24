#!/bin/bash

# LOAD LIBS
source lib/ui.sh
source lib/utils.sh

# LOAD MODULES
source modules/panel.sh

while true; do
    show_banner

    echo "1) Install Panel"
    echo "2) Install Wings"
    echo "3) Install Both"
    echo "4) Install Blueprint"
    echo "5) Install Themes/Addons"
    echo "6) Uninstall"
    echo "0) Exit"
    echo ""

    read -p "Select an option: " option

    case $option in
        1)
            install_panel
            ;;
        2)
            echo "Wings installer coming soon..."
            ;;
        3)
            install_panel
            ;;
        4)
            echo "Blueprint installer coming soon..."
            ;;
        5)
            echo "Themes/Addons coming soon..."
            ;;
        6)
            echo "Uninstall coming soon..."
            ;;
        0)
            exit 0
            ;;
        *)
            echo "Invalid option"
            sleep 1
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
done
