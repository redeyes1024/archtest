#!/usr/bin/env bash
# i3 keybind cheat sheet (yad when available, rofi fallback).

set -euo pipefail

i3_config="$HOME/.config/i3/config"
parser_script="$HOME/.config/i3/scripts/i3_keybinds_parser.py"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
default_rofi_theme="$HOME/.config/rofi/config.rasi"
rofi_msg="Cheat sheet only (selection does not trigger actions)"

notify_error() {
    local body="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low -i dialog-error "i3 Key Hints" "$body"
    fi
    printf '%s\n' "$body" >&2
}

if pidof rofi >/dev/null 2>&1; then
    pkill rofi
fi

if pidof yad >/dev/null 2>&1; then
    pkill yad
fi

command -v python3 >/dev/null 2>&1 || {
    notify_error "python3 is required for key hints."
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
rows_tsv="$(python3 "$parser_script" --format tsv "$i3_config" 2>/dev/null)"
parser_status=$?
set -e

if [[ $parser_status -ne 0 || -z "$rows_tsv" ]]; then
    notify_error "No keybind entries were parsed from $i3_config"
    exit 1
fi

if command -v yad >/dev/null 2>&1; then
    mapfile -t rows <<<"$rows_tsv"
    yad_args=(
        --center
        --title="i3 Keybind Cheat Sheet"
        --no-buttons
        --list
        --column=Key:
        --column=Description:
        --column=Command:
        --timeout-indicator=bottom
    )

    for row in "${rows[@]}"; do
        IFS=$'\t' read -r key desc cmd <<<"$row"
        [[ -n "${key:-}" ]] || continue
        yad_args+=("$key" "$desc" "$cmd")
    done

    GDK_BACKEND="${GDK_BACKEND:-x11}" yad "${yad_args[@]}"
    exit 0
fi

if ! command -v rofi >/dev/null 2>&1; then
    notify_error "Install rofi or yad to display key hints."
    exit 1
fi

fallback_lines="$(
    while IFS=$'\t' read -r key desc _; do
        [[ -n "$key" ]] || continue
        printf '%s - %s\n' "$key" "$desc"
    done <<<"$rows_tsv"
)"

if [[ -f "$rofi_theme" ]]; then
    printf '%s\n' "$fallback_lines" | rofi -dmenu -i -config "$rofi_theme" -mesg "$rofi_msg"
else
    printf '%s\n' "$fallback_lines" | rofi -dmenu -i -mesg "$rofi_msg"
fi
