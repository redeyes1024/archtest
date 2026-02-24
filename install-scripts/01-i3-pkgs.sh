#!/bin/bash
# 💫 https://github.com/LinuxBeginnings 💫 #
# i3wm Packages #
#
# Edit your desired packages here.
# WARNING! If you remove packages here, dotfiles may not work properly.
#

# Add extra packages wanted here
Extra=(
)

# Core userland for i3 + Xorg (replacements for Hyprland/Wayland-only tooling)
i3_packages=(
  arandr
  bc
  copyq
  curl
  dunst
  feh
  flameshot
  gvfs
  gvfs-mtp
  imagemagick
  inxi
  jq
  kitty
  kvantum
  lxappearance
  nano
  network-manager-applet
  pamixer
  pavucontrol
  picom
  playerctl
  polkit-gnome
  polybar
  python-requests
  python-pyquery
  qt5ct
  qt6ct
  qt6-svg
  rofi
  unzip # needed later
  wallust
  wget
  xclip
  xdg-user-dirs
  xdg-utils
  yad
)

# Optional / nice-to-have packages
i3_packages_2=(
  acpi
  brightnessctl
  btop
  cava
  fastfetch
  gnome-system-monitor
  libnotify
  mousepad
  mpv
  mpv-mpris
  nvtop
  pacman-contrib
  qalculate-gtk
  xidlehook
  xss-lock
  yt-dlp
)

# List of packages to uninstall as they conflict with i3/Xorg choices
uninstall=(
  cachyos-hyprland-settings
  cliphist
  hypridle
  hyprland
  hyprland-git
  hyprlock
  hyprpolkitagent
  mako
  rofi-lbonn-wayland
  rofi-lbonn-wayland-git
  swww
  swaync
  waybar
  wl-clipboard
  wlogout
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_i3-pkgs.log"

# conflicting packages removal
overall_failed=0
printf "\n%s - ${SKY_BLUE}Removing Wayland/Hyprland packages${RESET} (replacing with i3/Xorg) \n" "${NOTE}"
for PKG in "${uninstall[@]}"; do
  uninstall_package "$PKG" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    overall_failed=1
  fi
done

if [ $overall_failed -ne 0 ]; then
  echo -e "${ERROR} Some packages failed to uninstall. Please check the log."
fi

printf "\n%.0s" {1..1}

# Installation of main components
printf "\n%s - Installing ${SKY_BLUE}i3/Xorg necessary packages${RESET} .... \n" "${NOTE}"

for PKG1 in "${i3_packages[@]}" "${i3_packages_2[@]}" "${Extra[@]}"; do
  install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}
