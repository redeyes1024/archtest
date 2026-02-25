#!/usr/bin/env bash
# Keyboard backlight controls for i3/Xorg using brightnessctl.

set -euo pipefail

iDIR="$HOME/.config/swaync/icons"
backlight_device="*::kbd_backlight"
step=30

ensure_backlight_device() {
    brightnessctl -d "$backlight_device" -m >/dev/null 2>&1
}

get_kbd_backlight() {
    brightnessctl -d "$backlight_device" -m | cut -d, -f4 | tr -d '%'
}

get_icon_path() {
    local level="$1"
    local rounded=$(( (level + 19) / 20 * 20 ))
    if (( rounded > 100 )); then
        rounded=100
    fi
    printf "%s/brightness-%s.png" "$iDIR" "$rounded"
}

notify_user() {
    local level icon_path
    level="$(get_kbd_backlight)"
    icon_path="$(get_icon_path "$level")"
    notify-send -e \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -h int:value:"$level" \
        -u low \
        -i "$icon_path" \
        "Keyboard" "Brightness: ${level}%"
}

change_kbd_backlight() {
    local delta="$1"
    brightnessctl -d "$backlight_device" set "$delta" >/dev/null
    notify_user
}

if ! ensure_backlight_device; then
    notify-send -u low -i "$iDIR/error.png" "Keyboard" "No keyboard backlight device found."
    exit 1
fi

case "${1:---get}" in
    --get)
        get_kbd_backlight
        ;;
    --inc)
        change_kbd_backlight "${step}%+"
        ;;
    --dec)
        change_kbd_backlight "${step}%-"
        ;;
    *)
        echo "Usage: $0 [--get|--inc|--dec]" >&2
        exit 1
        ;;
esac
