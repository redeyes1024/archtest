#!/usr/bin/env bash
# Keyboard layout switcher for i3/Xorg via setxkbmap.

set -euo pipefail

notif_icon="$HOME/.config/swaync/images/ja.png"
error_icon="$HOME/.config/swaync/images/error.png"
laptops_conf="$HOME/.config/i3/UserConfigs/Laptops.conf"

KEYBOARD_LAYOUTS="${KEYBOARD_LAYOUTS:-us,ru}"
KEYBOARD_VARIANTS="${KEYBOARD_VARIANTS:-,}"
KEYBOARD_OPTIONS="${KEYBOARD_OPTIONS:-}"

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

if ! command -v setxkbmap >/dev/null 2>&1; then
    notify_user "Keyboard Layout" "setxkbmap is not installed." "$error_icon"
    exit 1
fi

IFS=',' read -r -a layout_mapping <<<"$KEYBOARD_LAYOUTS"
IFS=',' read -r -a variant_mapping <<<"$KEYBOARD_VARIANTS"

if [[ ${#layout_mapping[@]} -lt 1 || -z "${layout_mapping[0]}" ]]; then
    notify_user "Keyboard Layout" "No layouts configured in Laptops.conf." "$error_icon"
    exit 1
fi

trim_field() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf "%s" "$value"
}

current_layout() {
    local raw
    raw="$(setxkbmap -query | awk -F: '/layout/ { print $2; exit }')"
    raw="$(trim_field "$raw")"
    printf "%s" "${raw%%,*}"
}

current_variant() {
    local raw
    raw="$(setxkbmap -query | awk -F: '/variant/ { print $2; exit }')"
    raw="$(trim_field "$raw")"
    printf "%s" "${raw%%,*}"
}

variant_for_index() {
    local idx="$1"
    if [[ "$idx" -lt "${#variant_mapping[@]}" ]]; then
        printf "%s" "${variant_mapping[$idx]}"
    else
        printf ""
    fi
}

format_layout_label() {
    local layout="$1"
    local variant="$2"
    if [[ -n "$variant" ]]; then
        printf "%s(%s)" "$layout" "$variant"
    else
        printf "%s" "$layout"
    fi
}

index_for_current_layout() {
    local cur_layout="$1"
    local cur_variant="$2"

    for i in "${!layout_mapping[@]}"; do
        local candidate_layout candidate_variant
        candidate_layout="$(trim_field "${layout_mapping[$i]}")"
        candidate_variant="$(trim_field "$(variant_for_index "$i")")"
        if [[ "$candidate_layout" == "$cur_layout" ]]; then
            if [[ -z "$candidate_variant" || "$candidate_variant" == "$cur_variant" ]]; then
                printf "%s" "$i"
                return 0
            fi
        fi
    done

    printf "0"
}

apply_layout() {
    local idx="$1"
    local new_layout new_variant
    local cmd=(setxkbmap)

    new_layout="$(trim_field "${layout_mapping[$idx]}")"
    new_variant="$(trim_field "$(variant_for_index "$idx")")"

    cmd+=(-layout "$new_layout")
    if [[ -n "$new_variant" ]]; then
        cmd+=(-variant "$new_variant")
    fi
    if [[ -n "$KEYBOARD_OPTIONS" ]]; then
        cmd+=(-option "$KEYBOARD_OPTIONS")
    fi

    "${cmd[@]}"
    notify_user "Keyboard Layout" "$(format_layout_label "$new_layout" "$new_variant")" "$notif_icon"
}

show_status() {
    local layout variant
    layout="$(current_layout)"
    variant="$(current_variant)"
    format_layout_label "$layout" "$variant"
    printf "\n"
}

switch_layout() {
    local count idx next_idx
    local layout variant
    count="${#layout_mapping[@]}"

    if [[ "$count" -lt 2 ]]; then
        notify_user "Keyboard Layout" "Add at least two layouts in Laptops.conf to enable cycling." "$error_icon"
        exit 1
    fi

    layout="$(current_layout)"
    variant="$(current_variant)"
    idx="$(index_for_current_layout "$layout" "$variant")"
    next_idx=$(( (idx + 1) % count ))
    apply_layout "$next_idx"
}

case "${1:-switch}" in
    status)
        show_status
        ;;
    switch)
        switch_layout
        ;;
    *)
        echo "Usage: $0 [status|switch]" >&2
        exit 1
        ;;
esac
