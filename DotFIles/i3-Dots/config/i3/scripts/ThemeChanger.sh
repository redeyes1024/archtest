#!/usr/bin/env bash
set -euo pipefail

require() {
  command -v "$1" >/dev/null 2>&1 || {
    printf '%s\n' "Missing dependency: $1" >&2
    exit 127
  }
}

have_notify() {
  command -v notify-send >/dev/null 2>&1
}

wait_for_templates() {
  local max_tries=80
  local delay_s=0.1
  local files=("$@")
  local i

  for ((i = 1; i <= max_tries; i++)); do
    local all_ready=1
    local f
    for f in "${files[@]}"; do
      [[ -s "$f" ]] || {
        all_ready=0
        break
      }
    done
    [[ $all_ready -eq 1 ]] && return 0
    sleep "$delay_s"
  done
  return 1
}

require wallust
require rofi

set +e
choice="$(
  wallust theme list \
    | sed -e '1d' -e 's/^- //' \
    | rofi -dmenu -i -p 'Select Global Theme'
)"
prompt_status=$?
set -e

if ((prompt_status != 0)) || [[ -z "$choice" ]]; then
  exit 0
fi

if wallust theme -- "$choice"; then
  wait_for_templates \
    "${HOME}/.config/rofi/wallust/colors-rofi.rasi" \
    "${HOME}/.config/kitty/kitty-themes/01-Wallust.conf" || true

  if [[ -x "${HOME}/.config/i3/scripts/Refresh.sh" ]]; then
    "${HOME}/.config/i3/scripts/Refresh.sh" >/dev/null 2>&1 || true
  fi

  have_notify && notify-send -a ThemeChanger "Global theme changed" "Selected: ${choice}"
else
  have_notify && notify-send -u critical -a ThemeChanger "Failed to apply theme" "${choice}"
  exit 1
fi
