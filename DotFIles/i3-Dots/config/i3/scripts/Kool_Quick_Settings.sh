#!/usr/bin/env bash
# Rofi menu for i3 quick settings and helper actions.

set -euo pipefail

rofi_theme="$HOME/.config/rofi/config-edit.rasi"
default_rofi_theme="$HOME/.config/rofi/config.rasi"
msg="Choose an i3 action"

scripts_dir="$HOME/.config/i3/scripts"
i3_config="$HOME/.config/i3/config"
user_configs="$HOME/.config/i3/UserConfigs"
monitor_profiles="$HOME/.config/i3/Monitor_Profiles"
picom_config="$HOME/.config/picom/picom.conf"
polybar_config="$HOME/.config/polybar/config.ini"

read -r -a terminal_cmd <<<"${TERMINAL:-kitty}"
read -r -a editor_cmd <<<"${EDITOR:-nano}"

if [[ ${#terminal_cmd[@]} -eq 0 ]]; then
    terminal_cmd=("kitty")
fi
if [[ ${#editor_cmd[@]} -eq 0 ]]; then
    editor_cmd=("nano")
fi

notify_info() {
    local body="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low -i dialog-information "i3 Quick Settings" "$body"
    fi
}

notify_error() {
    local body="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low -i dialog-error "i3 Quick Settings" "$body"
    fi
    printf '%s\n' "$body" >&2
}

open_in_editor() {
    local file="$1"
    mkdir -p "$(dirname "$file")"
    [[ -f "$file" ]] || touch "$file"

    if command -v "${terminal_cmd[0]}" >/dev/null 2>&1; then
        "${terminal_cmd[@]}" -e "${editor_cmd[@]}" "$file" &
        return 0
    fi

    if command -v xterm >/dev/null 2>&1; then
        xterm -e "${editor_cmd[@]}" "$file" &
        return 0
    fi

    "${editor_cmd[@]}" "$file"
}

run_script() {
    local script_path="$1"
    shift || true
    if [[ ! -f "$script_path" ]]; then
        notify_error "Missing script: $script_path"
        return 1
    fi
    bash "$script_path" "$@"
}

run_if_installed() {
    local binary="$1"
    local missing_msg="$2"
    if command -v "$binary" >/dev/null 2>&1; then
        "$binary" &
        return 0
    fi
    notify_error "$missing_msg"
    return 1
}

open_gtk_settings() {
    if command -v nwg-look >/dev/null 2>&1; then
        nwg-look &
        return 0
    fi
    if command -v lxappearance >/dev/null 2>&1; then
        lxappearance &
        return 0
    fi
    notify_error "Install nwg-look or lxappearance for GTK settings."
    return 1
}

menu() {
    cat <<'EOF'
--- I3 CUSTOMIZATION ---
Edit i3 config
Edit autostart script
Edit laptop script options
Edit default monitor profile
Edit picom config
Edit polybar config
--- I3 UTILITIES ---
Search keybinds
Show keybind cheat sheet
Choose monitor profile
Choose Rofi theme
Choose Kitty theme
Open clipboard manager
Choose wallust theme preset
Switch dark/light theme
Apply wallust to current wallpaper
Refresh i3 and polybar colors
Open power menu
Lock screen
--- DESKTOP TOOLS ---
Open GTK settings
Open Qt6 settings
Open Qt5 settings
EOF
}

if [[ ! -f "$rofi_theme" ]]; then
    rofi_theme="$default_rofi_theme"
fi

if pidof rofi >/dev/null 2>&1; then
    pkill rofi
fi

if ! command -v rofi >/dev/null 2>&1; then
    notify_error "Install rofi to use quick settings."
    exit 1
fi

choice="$(
    if [[ -f "$rofi_theme" ]]; then
        menu | rofi -i -dmenu -config "$rofi_theme" -mesg "$msg" || true
    else
        menu | rofi -i -dmenu -mesg "$msg" || true
    fi
)"

[[ -n "$choice" ]] || exit 0

case "$choice" in
    "--- I3 CUSTOMIZATION ---" | "--- I3 UTILITIES ---" | "--- DESKTOP TOOLS ---")
        exit 0
        ;;
    "Edit i3 config")
        open_in_editor "$i3_config"
        ;;
    "Edit autostart script")
        open_in_editor "$scripts_dir/autostart.sh"
        ;;
    "Edit laptop script options")
        open_in_editor "$user_configs/Laptops.conf"
        ;;
    "Edit default monitor profile")
        open_in_editor "$monitor_profiles/default.sh"
        ;;
    "Edit picom config")
        open_in_editor "$picom_config"
        ;;
    "Edit polybar config")
        open_in_editor "$polybar_config"
        ;;
    "Search keybinds")
        run_script "$scripts_dir/KeyBinds.sh"
        ;;
    "Show keybind cheat sheet")
        run_script "$scripts_dir/KeyHints.sh"
        ;;
    "Choose monitor profile")
        run_script "$scripts_dir/MonitorProfiles.sh"
        ;;
    "Choose Rofi theme")
        run_script "$scripts_dir/RofiThemeSelector.sh"
        ;;
    "Choose Kitty theme")
        run_script "$scripts_dir/Kitty_themes.sh"
        ;;
    "Open clipboard manager")
        run_script "$scripts_dir/ClipManager.sh"
        ;;
    "Choose wallust theme preset")
        run_script "$scripts_dir/ThemeChanger.sh"
        ;;
    "Switch dark/light theme")
        run_script "$scripts_dir/DarkLight.sh"
        ;;
    "Apply wallust to current wallpaper")
        run_script "$scripts_dir/WallustFeh.sh"
        ;;
    "Refresh i3 and polybar colors")
        run_script "$scripts_dir/Refresh.sh"
        notify_info "Refreshed i3/polybar colors and reload hooks."
        ;;
    "Open power menu")
        run_script "$scripts_dir/powermenu.sh"
        ;;
    "Lock screen")
        run_script "$scripts_dir/lock.sh"
        ;;
    "Open GTK settings")
        open_gtk_settings
        ;;
    "Open Qt6 settings")
        run_if_installed "qt6ct" "Install qt6ct for Qt6 settings."
        ;;
    "Open Qt5 settings")
        run_if_installed "qt5ct" "Install qt5ct for Qt5 settings."
        ;;
    *)
        exit 0
        ;;
esac
