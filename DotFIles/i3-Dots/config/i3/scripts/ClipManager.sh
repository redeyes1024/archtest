#!/usr/bin/env bash
set -u
set -o pipefail

rofi_theme="$HOME/.config/rofi/config-clipboard.rasi"

notify_error() {
  local msg="$1"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low -i dialog-error "Clipboard manager" "$msg"
  fi
  echo "$msg" >&2
}

show_copyq_menu() {
  command -v copyq >/dev/null 2>&1 || return 1

  if ! pgrep -u "$USER" -x copyq >/dev/null 2>&1; then
    copyq --start-server >/dev/null 2>&1 || true
    sleep 0.2
  fi

  copyq menu
}

show_rofi_xclip_picker() {
  command -v rofi >/dev/null 2>&1 || return 1
  command -v xclip >/dev/null 2>&1 || return 1

  local clipboard_text
  local primary_text
  clipboard_text="$(xclip -selection clipboard -o 2>/dev/null || true)"
  primary_text="$(xclip -selection primary -o 2>/dev/null || true)"

  if [[ -z "$clipboard_text" && -z "$primary_text" ]]; then
    return 1
  fi

  local rofi_cmd=(rofi -dmenu -i -p clipboard)
  if [[ -f "$rofi_theme" ]]; then
    rofi_cmd+=(-config "$rofi_theme")
  fi

  local selected
  selected="$(
    printf '%s\n%s\n' "$clipboard_text" "$primary_text" \
      | awk 'NF && !seen[$0]++' \
      | "${rofi_cmd[@]}"
  )"

  [[ -n "$selected" ]] || return 1

  printf '%s' "$selected" | xclip -selection clipboard
  printf '%s' "$selected" | xclip -selection primary
}

if show_copyq_menu; then
  exit 0
fi

if show_rofi_xclip_picker; then
  exit 0
fi

notify_error "Install copyq (recommended) or rofi + xclip for clipboard workflow."
exit 1
