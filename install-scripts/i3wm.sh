#!/bin/bash
# 💫 https://github.com/LinuxBeginnings 💫 #
# i3wm + Xorg #

xorg=(
  xorg-server
  xorg-xinit
  xorg-xrandr
  xorg-xsetroot
  xorg-xinput
)

i3=(
  i3-wm
  i3status
  i3lock
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_i3wm.log"

printf "${NOTE} - Installing ${SKY_BLUE}Xorg${RESET} base packages...\n"
for PKG in "${xorg[@]}"; do
  install_package_pacman "$PKG" "$LOG"
done

printf "\n%.0s" {1..1}

# Check if i3 is installed
if command -v i3 >/dev/null 2>&1; then
  printf "$NOTE - ${YELLOW} i3wm is already installed.${RESET} No action required.\n"
else
  printf "$INFO - i3wm not found. ${SKY_BLUE} Installing i3wm core...${RESET}\n"
  for PKG in "${i3[@]}"; do
    install_package_pacman "$PKG" "$LOG"
  done
fi

printf "\n%.0s" {1..2}
