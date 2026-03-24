#!/bin/bash

# Colors
BLUE="\e[38;5;39m"
PURPLE="\e[38;5;93m"
CYAN="\e[36m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# ================= BANNER =================

show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "██╗   ██╗ ██████╗ ██╗  ██╗███████╗██╗     ███╗   ██╗ ██████╗ ██████╗ ███████╗"
    echo "██║   ██║██╔═══██╗╚██╗██╔╝██╔════╝██║     ████╗  ██║██╔═══██╗██╔══██╗██╔════╝"
    echo "██║   ██║██║   ██║ ╚███╔╝ █████╗  ██║     ██╔██╗ ██║██║   ██║██║  ██║█████╗  "
    echo "╚██╗ ██╔╝██║   ██║ ██╔██╗ ██╔══╝  ██║     ██║╚██╗██║██║   ██║██║  ██║██╔══╝  "
    echo " ╚████╔╝ ╚██████╔╝██╔╝ ██╗███████╗███████╗██║ ╚████║╚██████╔╝██████╔╝███████╗"
    echo "  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝"
    echo -e "${RESET}"
    echo -e "${CYAN}           VoxelNodes Installer (Pro Edition)${RESET}"
    echo ""
}

# ================= SPINNER =================

spinner() {
    local pid=$!
    local delay=0.08
    local spin='|/-\'

    while ps -p $pid > /dev/null 2>&1; do
        for i in $(seq 0 3); do
            printf "\r${BLUE}➤ Processing... ${spin:$i:1}${RESET}"
            sleep $delay
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
