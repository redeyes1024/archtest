#!/usr/bin/env bash
# Media controls via playerctl.

music_icon="$HOME/.config/swaync/icons/music.png"

show_music_notification() {
    local status song_title song_artist
    status="$(playerctl status 2>/dev/null)"

    if [[ "$status" == "Playing" ]]; then
        song_title="$(playerctl metadata title 2>/dev/null)"
        song_artist="$(playerctl metadata artist 2>/dev/null)"
        notify-send -e -u low -i "$music_icon" "Now Playing" "${song_title} by ${song_artist}"
    elif [[ "$status" == "Paused" ]]; then
        notify-send -e -u low -i "$music_icon" "Playback" "Paused"
    fi
}

play_next() {
    playerctl next
    show_music_notification
}

play_previous() {
    playerctl previous
    show_music_notification
}

toggle_play_pause() {
    playerctl play-pause
    sleep 0.1
    show_music_notification
}

stop_playback() {
    playerctl stop
    notify-send -e -u low -i "$music_icon" "Playback" "Stopped"
}

case "$1" in
"--nxt")
    play_next
    ;;
"--prv")
    play_previous
    ;;
"--pause")
    toggle_play_pause
    ;;
"--stop")
    stop_playback
    ;;
*)
    echo "Usage: $0 [--nxt|--prv|--pause|--stop]"
    exit 1
    ;;
esac
