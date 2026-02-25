#!/usr/bin/env bash
# Rofi-driven monitor profile chooser for i3/Xorg.

set -euo pipefail

iDIR="$HOME/.config/swaync/images"
monitor_dir="$HOME/.config/i3/Monitor_Profiles"
last_profile="$monitor_dir/.last_profile"
rofi_theme="$HOME/.config/rofi/config-Monitors.rasi"
default_rofi_theme="$HOME/.config/rofi/config.rasi"
polybar_launch="$HOME/.config/polybar/launch.sh"

notify_user() {
    notify-send -u low -i "$1" "$2" "$3"
}

if pidof rofi >/dev/null 2>&1; then
    pkill rofi
fi

if [[ ! -d "$monitor_dir" ]]; then
    notify_user "$iDIR/error.png" "Monitor Profiles" "Directory not found: $monitor_dir"
    exit 1
fi

if [[ ! -f "$rofi_theme" ]]; then
    rofi_theme="$default_rofi_theme"
fi

mapfile -t profile_scripts < <(
    find "$monitor_dir" -maxdepth 1 -type f -name "*.sh" -printf "%f\n" |
        sed 's/\.sh$//' |
        sort -V
)

if [[ ${#profile_scripts[@]} -eq 0 ]]; then
    notify_user "$iDIR/error.png" "Monitor Profiles" "No profile scripts found in $monitor_dir"
    exit 1
fi

selected_row=0
if [[ -f "$last_profile" ]]; then
    last_selected="$(<"$last_profile")"
    for i in "${!profile_scripts[@]}"; do
        if [[ "${profile_scripts[$i]}" == "$last_selected" ]]; then
            selected_row="$i"
            break
        fi
    done
fi

chosen_profile="$(
    printf "%s\n" "${profile_scripts[@]}" |
        rofi -dmenu -i \
            -p "Monitor Profile" \
            -mesg "Select an xrandr monitor profile script" \
            -config "$rofi_theme" \
            -selected-row "$selected_row" ||
        true
)"

if [[ -z "$chosen_profile" ]]; then
    exit 0
fi

profile_script="$monitor_dir/$chosen_profile.sh"
if [[ ! -f "$profile_script" ]]; then
    notify_user "$iDIR/error.png" "Monitor Profiles" "Profile not found: $chosen_profile"
    exit 1
fi

if bash "$profile_script"; then
    printf "%s" "$chosen_profile" >"$last_profile"

    if [[ -x "$polybar_launch" ]]; then
        "$polybar_launch" >/dev/null 2>&1 || true
    fi

    notify_user "$iDIR/ja.png" "Monitor Profile Loaded" "$chosen_profile"
else
    notify_user "$iDIR/error.png" "Monitor Profile Error" "Failed to apply $chosen_profile"
    exit 1
fi
