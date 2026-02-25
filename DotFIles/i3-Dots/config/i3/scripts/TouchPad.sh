#!/usr/bin/env bash
# Touchpad toggle for i3/Xorg via xinput.

set -euo pipefail

notif_icon="$HOME/.config/swaync/images/ja.png"
error_icon="$HOME/.config/swaync/images/error.png"
laptops_conf="$HOME/.config/i3/UserConfigs/Laptops.conf"

TOUCHPAD_DEVICE="${TOUCHPAD_DEVICE:-}"

if [[ -f "$laptops_conf" ]]; then
    # shellcheck source=/dev/null
    source "$laptops_conf"
fi

notify_user() {
    local title="$1"
    local body="$2"
    local icon="$3"
    notify-send -u low -i "$icon" "$title" "$body"
}

if ! command -v xinput >/dev/null 2>&1; then
    notify_user "Touchpad" "xinput is not installed." "$error_icon"
    exit 1
fi

resolve_touchpad_id() {
    local configured_name="${TOUCHPAD_DEVICE:-}"
    local detected_name=""
    local device_id=""

    if [[ -n "$configured_name" ]]; then
        device_id="$(xinput list --id-only "$configured_name" 2>/dev/null || true)"
        if [[ -n "$device_id" ]]; then
            printf "%s" "$device_id"
            return 0
        fi
    fi

    detected_name="$(xinput list --name-only | awk 'tolower($0) ~ /touchpad/ { print; exit }')"
    if [[ -n "$detected_name" ]]; then
        device_id="$(xinput list --id-only "$detected_name" 2>/dev/null || true)"
        if [[ -n "$device_id" ]]; then
            printf "%s" "$device_id"
            return 0
        fi
    fi

    return 1
}

touchpad_id="$(resolve_touchpad_id || true)"
if [[ -z "$touchpad_id" ]]; then
    notify_user "Touchpad" "Touchpad device not found. Set TOUCHPAD_DEVICE in Laptops.conf." "$error_icon"
    exit 1
fi

is_enabled() {
    xinput list-props "$touchpad_id" |
        awk -F: '/Device Enabled/ { gsub(/[[:space:]]/, "", $2); print $2; exit }'
}

set_enabled() {
    local target="$1"
    if [[ "$target" == "1" ]]; then
        xinput enable "$touchpad_id"
        notify_user "Touchpad" "Enabled" "$notif_icon"
    else
        xinput disable "$touchpad_id"
        notify_user "Touchpad" "Disabled" "$notif_icon"
    fi
}

action="${1:-toggle}"
current_state="$(is_enabled)"

case "$action" in
    status)
        if [[ "$current_state" == "1" ]]; then
            echo "enabled"
        else
            echo "disabled"
        fi
        ;;
    enable)
        set_enabled "1"
        ;;
    disable)
        set_enabled "0"
        ;;
    toggle)
        if [[ "$current_state" == "1" ]]; then
            set_enabled "0"
        else
            set_enabled "1"
        fi
        ;;
    *)
        echo "Usage: $0 [status|enable|disable|toggle]" >&2
        exit 1
        ;;
esac
