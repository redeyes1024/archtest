#!/bin/bash
set -euo pipefail

themes_dir="$HOME/.config/rofi/themes"
config_file="$HOME/.config/rofi/config.rasi"

[ -d "$themes_dir" ] || exit 0
[ -f "$config_file" ] || exit 0

selected="$(
  find "$themes_dir" -maxdepth 1 -type f -name '*.rasi' -printf '%f\n' 2>/dev/null | \
    sort | rofi -dmenu -i -p "Rofi theme"
)"

[ -n "${selected:-}" ] || exit 0

tmp="$(mktemp)"
awk -v theme="$selected" '
  BEGIN { done=0 }
  /^\s*@theme\s+"/ {
    if (!done) {
      print "@theme \"~/.config/rofi/themes/" theme "\""
      done=1
      next
    }
  }
  { print }
  END {
    if (!done) {
      print "@theme \"~/.config/rofi/themes/" theme "\""
    }
  }
' "$config_file" > "$tmp"

mv "$tmp" "$config_file"
