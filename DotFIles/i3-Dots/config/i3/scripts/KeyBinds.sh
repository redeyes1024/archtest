#!/usr/bin/env bash
# Searchable i3 keybind list shown in rofi.

set -euo pipefail

i3_config="$HOME/.config/i3/config"
parser_script="$HOME/.config/i3/scripts/i3_keybinds_parser.py"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
default_rofi_theme="$HOME/.config/rofi/config.rasi"
msg="Search keybinds (selection is read-only)"

notify_error() {
    local body="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low -i dialog-error "i3 Keybinds" "$body"
    fi
    printf '%s\n' "$body" >&2
}

if pidof rofi >/dev/null 2>&1; then
    pkill rofi
fi

if pidof yad >/dev/null 2>&1; then
    pkill yad
fi

command -v rofi >/dev/null 2>&1 || {
    notify_error "Install rofi to search keybinds."
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    notify_error "python3 is required for keybind parsing."
    exit 1
}

if [[ ! -f "$parser_script" ]]; then
    notify_error "Parser not found: $parser_script"
    exit 1
fi

if [[ ! -f "$i3_config" ]]; then
    notify_error "i3 config not found: $i3_config"
    exit 1
fi

if [[ ! -f "$rofi_theme" ]]; then
    rofi_theme="$default_rofi_theme"
fi

set +e
display_keybinds="$(python3 "$parser_script" --format rofi "$i3_config" 2>/dev/null)"
parser_status=$?
set -e

if [[ $parser_status -ne 0 || -z "$display_keybinds" ]]; then
    notify_error "No keybind entries were parsed from $i3_config"
    exit 1
fi

if [[ -f "$rofi_theme" ]]; then
    printf '%s\n' "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
else
    printf '%s\n' "$display_keybinds" | rofi -dmenu -i -mesg "$msg"
fi
