#!/bin/bash
# 💫 https://github.com/LinuxBeginnings 💫 #
# SDDM Log-in Manager #

sddm=(
  qt6-declarative
  qt6-svg
  qt6-virtualkeyboard
  qt6-multimedia-ffmpeg
  qt5-quickcontrols2
  sddm
)

# login managers to attempt to disable
login=(
  lightdm
  gdm3
  gdm
  lxdm
  lxdm-gtk3
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
  echo "${ERROR} Failed to change directory to $PARENT_DIR"
  exit 1
}

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm.log"

# Install SDDM and SDDM theme
printf "${NOTE} Installing sddm and dependencies........\n"
for package in "${sddm[@]}"; do
  install_package "$package" "$LOG"
done

printf "\n%.0s" {1..1}

# Check if other login managers installed and disabling its service before enabling sddm
for login_manager in "${login[@]}"; do
  if pacman -Qs "$login_manager" >/dev/null 2>&1; then
    sudo systemctl disable "$login_manager.service" >>"$LOG" 2>&1
    echo "$login_manager disabled." >>"$LOG" 2>&1
  fi
done

# Double check with systemctl
for manager in "${login[@]}"; do
  if systemctl is-active --quiet "$manager" >/dev/null 2>&1; then
    echo "$manager is active, disabling it..." >>"$LOG" 2>&1
    sudo systemctl disable "$manager" --now >>"$LOG" 2>&1
  fi
done

printf "\n%.0s" {1..1}
printf "${INFO} Activating sddm service........\n"
sudo systemctl enable sddm

dpi_conf_dir="/etc/sddm.conf.d"
dpi_conf_file="$dpi_conf_dir/dpi.conf"
dpi_value="144"

printf "${INFO} Setting SDDM DPI to ${dpi_value}........\n"
if [ ! -d "$dpi_conf_dir" ]; then
  sudo mkdir -p "$dpi_conf_dir" 2>&1 | tee -a "$LOG"
fi

sudo tee "$dpi_conf_file" > /dev/null <<EOF
[General]
DisplayServer=x11
# This forces Qt6 to scale the UI elements (buttons/boxes)
GreeterEnvironment=QT_SCREEN_SCALE_FACTORS=2,QT_FONT_DPI=192

[X11]
ServerArguments=-nolisten tcp -dpi 144
EOF
echo "Configured $dpi_conf_file with DPI $dpi_value." | tee -a "$LOG"

x_sessions_dir=/usr/share/xsessions
[ ! -d "$x_sessions_dir" ] && {
  printf "$CAT - $x_sessions_dir not found, creating...\n"
  sudo mkdir "$x_sessions_dir" 2>&1 | tee -a "$LOG"
}


printf "\n%.0s" {1..2}

