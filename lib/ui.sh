#!/bin/bash

# COLORS
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

PURPLE="\033[38;5;135m"
BLUE="\033[38;5;63m"
CYAN="\033[36m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"

# CLEAR
clear_screen() {
    clear
}

# LOGO
show_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "██╗   ██╗ ██████╗ ██╗  ██╗███████╗██╗     ███╗   ██╗ ██████╗ ██████╗ ███████╗"
    echo "██║   ██║██╔═══██╗╚██╗██╔╝██╔════╝██║     ████╗  ██║██╔═══██╗██╔══██╗██╔════╝"
    echo "██║   ██║██║   ██║ ╚███╔╝ █████╗  ██║     ██╔██╗ ██║██║   ██║██║  ██║█████╗  "
    echo "╚██╗ ██╔╝██║   ██║ ██╔██╗ ██╔══╝  ██║     ██║╚██╗██║██║   ██║██║  ██║██╔══╝  "
    echo " ╚████╔╝ ╚██████╔╝██╔╝ ██╗███████╗███████╗██║ ╚████║╚██████╔╝██████╔╝███████╗"
    echo "  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝"
    echo -e "${RESET}"
    echo -e "${CYAN}VoxelNodes Installer (Pro Edition)${RESET}"
    echo ""
}

# LOADING ANIMATION
spinner() {
    local pid=$!
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${CYAN}[%c]${RESET} " "${spin:$i:1}"
        sleep .1
    done
    printf "\r"
}

# STEP DISPLAY
step() {
    echo -e "${BLUE}➤ $1${RESET}"
}

success() {
    echo -e "${GREEN}✔ $1${RESET}"
}

error() {
    echo -e "${RED}✖ $1${RESET}"
}

warn() {
    echo -e "${YELLOW}⚠ $1${RESET}"
}            sleep $delay
        done
    done

    printf "\r"
}

# ================= STEP =================

step() {
    echo -e "${BLUE}➤ $1...${RESET}"
}

# ================= RUN WITH SPINNER =================

run_step() {
    local msg=$1
    local cmd=$2

    echo -ne "${BLUE}➤ $msg...${RESET}"

    (eval "$cmd" > /tmp/voxelnodes.log 2>&1) &
    spinner

    if [ $? -ne 0 ]; then
        echo -e "\r${RED}✖ Failed: $msg${RESET}"
        echo "Check logs: /tmp/voxelnodes.log"
        exit 1
    fi

    echo -e "\r${GREEN}✔ $msg${RESET}"
}

# ================= SUCCESS =================

done_msg() {
    echo -e "${GREEN}✔ $1${RESET}"
}

# ================= ERROR =================

fail_msg() {
    echo -e "${RED}✖ $1${RESET}"
}
