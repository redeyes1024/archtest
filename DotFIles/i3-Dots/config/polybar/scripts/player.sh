#!/usr/bin/env bash
set -euo pipefail

MAX_LEN="${PLAYER_MAX_LEN:-50}"

if ! command -v playerctl >/dev/null 2>&1; then
  printf "\n"
  exit 0
fi

status="$(playerctl status 2>/dev/null || true)"

if [[ "$status" != "Playing" && "$status" != "Paused" ]]; then
  printf "\n"
  exit 0
fi

track="$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || true)"
if [[ -z "$track" ]]; then
  track="$(playerctl metadata --format '{{title}}' 2>/dev/null || true)"
fi
track="${track//$'\n'/ }"
track="${track:-No media}"

if (( ${#track} > MAX_LEN )); then
  track="${track:0:MAX_LEN-1}…"
fi

if [[ "$status" == "Playing" ]]; then
  printf " %s\n" "$track"
else
  printf "󰏤 %s\n" "$track"
fi
