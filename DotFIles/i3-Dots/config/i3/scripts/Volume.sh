#!/usr/bin/env bash
# Volume and microphone controls for i3/Xorg.

iDIR="$HOME/.config/swaync/icons"
sDIR="$HOME/.config/i3/scripts"

get_volume() {
    if [[ "$(pamixer --get-mute)" == "true" ]]; then
        echo "Muted"
        return
    fi

    local volume
    volume=$(pamixer --get-volume)
    if [[ "$volume" -eq 0 ]]; then
        echo "Muted"
    else
        echo "$volume %"
    fi
}

get_icon() {
    if [[ "$(pamixer --get-mute)" == "true" ]]; then
        echo "$iDIR/volume-mute.png"
        return
    fi

    local current
    current=$(pamixer --get-volume)
    if [[ "$current" -le 30 ]]; then
        echo "$iDIR/volume-low.png"
    elif [[ "$current" -le 60 ]]; then
        echo "$iDIR/volume-mid.png"
    else
        echo "$iDIR/volume-high.png"
    fi
}

play_volume_sound() {
    if [[ -x "$sDIR/Sounds.sh" ]]; then
        "$sDIR/Sounds.sh" --volume >/dev/null 2>&1
    fi
}

notify_user() {
    local muted level
    muted="$(pamixer --get-mute)"
    level="$(pamixer --get-volume)"

    if [[ "$muted" == "true" || "$level" -eq 0 ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif \
            -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$(get_icon)" \
            "Volume" "Muted"
    else
        notify-send -e -h int:value:"$level" -h string:x-canonical-private-synchronous:volume_notif \
            -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$(get_icon)" \
            "Volume Level" "${level}%"
        play_volume_sound
    fi
}

inc_volume() {
    if [[ "$(pamixer --get-mute)" == "true" ]]; then
        toggle_mute
    else
        pamixer -i "$1" --allow-boost --set-limit 150 && notify_user
    fi
}

dec_volume() {
    if [[ "$(pamixer --get-mute)" == "true" ]]; then
        toggle_mute
    else
        pamixer -d "$1" && notify_user
    fi
}

toggle_mute() {
    if [[ "$(pamixer --get-mute)" == "false" ]]; then
        pamixer -m && notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true \
            -i "$iDIR/volume-mute.png" "Volume" "Muted"
    else
        pamixer -u && notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true \
            -i "$(get_icon)" "Volume" "Unmuted"
    fi
}

toggle_mic() {
    if [[ "$(pamixer --default-source --get-mute)" == "false" ]]; then
        pamixer --default-source -m && notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true \
            -i "$iDIR/microphone-mute.png" "Microphone" "Muted"
    else
        pamixer --default-source -u && notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true \
            -i "$iDIR/microphone.png" "Microphone" "Unmuted"
    fi
}

get_mic_icon() {
    local muted current
    muted="$(pamixer --default-source --get-mute)"
    current="$(pamixer --default-source --get-volume)"
    if [[ "$muted" == "true" || "$current" -eq 0 ]]; then
        echo "$iDIR/microphone-mute.png"
    else
        echo "$iDIR/microphone.png"
    fi
}

notify_mic_user() {
    local muted level icon
    muted="$(pamixer --default-source --get-mute)"
    level="$(pamixer --default-source --get-volume)"

    if [[ "$muted" == "true" || "$level" -eq 0 ]]; then
        icon="$iDIR/microphone-mute.png"
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif \
            -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$icon" \
            "Mic Level" "Muted"
    else
        icon="$iDIR/microphone.png"
        notify-send -e -h int:value:"$level" -h string:x-canonical-private-synchronous:volume_notif \
            -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$icon" \
            "Mic Level" "${level}%"
    fi
}

inc_mic_volume() {
    if [[ "$(pamixer --default-source --get-mute)" == "true" ]]; then
        toggle_mic
    else
        pamixer --default-source -i 5 && notify_mic_user
    fi
}

dec_mic_volume() {
    if [[ "$(pamixer --default-source --get-mute)" == "true" ]]; then
        toggle_mic
    else
        pamixer --default-source -d 5 && notify_mic_user
    fi
}

case "$1" in
"--get")
    get_volume
    ;;
"--inc")
    inc_volume 5
    ;;
"--inc-precise")
    inc_volume 1
    ;;
"--dec")
    dec_volume 5
    ;;
"--dec-precise")
    dec_volume 1
    ;;
"--toggle")
    toggle_mute
    ;;
"--toggle-mic")
    toggle_mic
    ;;
"--get-icon")
    get_icon
    ;;
"--get-mic-icon")
    get_mic_icon
    ;;
"--mic-inc")
    inc_mic_volume
    ;;
"--mic-dec")
    dec_mic_volume
    ;;
*)
    get_volume
    ;;
esac
