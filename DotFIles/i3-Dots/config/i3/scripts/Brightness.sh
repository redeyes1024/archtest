#!/usr/bin/env bash
# Screen brightness controls for i3/Xorg using brightnessctl.

iDIR="$HOME/.config/swaync/icons"
step=10

get_brightness() {
    brightnessctl -m | cut -d, -f4 | tr -d '%'
}

get_icon_path() {
    local brightness=$1
    local level=$(( (brightness + 19) / 20 * 20 ))
    if (( level > 100 )); then
        level=100
    fi
    echo "$iDIR/brightness-${level}.png"
}

send_notification() {
    local brightness=$1
    local icon_path=$2

    notify-send -e \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -h int:value:"$brightness" \
        -u low \
        -i "$icon_path" \
        "Screen" "Brightness: ${brightness}%"
}

change_brightness() {
    local delta=$1
    local current new icon

    current=$(get_brightness)
    new=$((current + delta))

    (( new < 5 )) && new=5
    (( new > 100 )) && new=100

    brightnessctl set "${new}%"
    icon=$(get_icon_path "$new")
    send_notification "$new" "$icon"
}

case "$1" in
    "--get")
        get_brightness
        ;;
    "--inc")
        change_brightness "$step"
        ;;
    "--dec")
        change_brightness "-$step"
        ;;
    *)
        get_brightness
        ;;
esac
