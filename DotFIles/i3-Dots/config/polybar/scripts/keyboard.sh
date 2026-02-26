#!/usr/bin/env bash
set -euo pipefail

layout=""
if [[ -x "$HOME/.config/i3/scripts/KeyboardLayout.sh" ]]; then
  layout="$(bash "$HOME/.config/i3/scripts/KeyboardLayout.sh" status 2>/dev/null || true)"
fi

if [[ -z "$layout" ]] && command -v setxkbmap >/dev/null 2>&1; then
  layout="$(setxkbmap -query 2>/dev/null | awk -F: '/layout/ {gsub(/[[:space:]]/, "", $2); print toupper($2); exit}')"
fi

layout="${layout:-N/A}"

caps_state="off"
if command -v xset >/dev/null 2>&1; then
  caps_state="$(xset q 2>/dev/null | awk '/Caps Lock:/ {print tolower($4); exit}' || true)"
fi

if [[ "$caps_state" == "on" ]]; then
  printf " %s 󰪛\n" "$layout"
else
  printf " %s\n" "$layout"
fi
