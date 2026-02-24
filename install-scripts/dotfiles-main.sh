#!/bin/bash
# 💫 https://github.com/LinuxBeginnings 💫 #
# i3-Dots (local) #


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

# Install i3 dotfiles from this repository
DOTS_DIR="$PARENT_DIR/DotFIles/i3-Dots"
printf "${NOTE} Installing ${SKY_BLUE}i3wm dotfiles${RESET} from ${YELLOW}$DOTS_DIR${RESET}....\n"

if [ -d "$DOTS_DIR" ]; then
  cd "$DOTS_DIR" || exit 1
  chmod +x copy.sh
  ./copy.sh
else
  echo -e "$ERROR Can't find ${YELLOW}$DOTS_DIR${RESET}. Please ensure the i3 dotfiles folder exists."
  exit 1
fi

printf "\n%.0s" {1..2}