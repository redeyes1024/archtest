#!/usr/bin/env bash
set -euo pipefail

if ! command -v brightnessctl >/dev/null 2>&1; then
  printf "󰃠 --%%\n"
  exit 0
fi

level="$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo 0)"
level="${level:-0}"
if ! [[ "$level" =~ ^[0-9]+$ ]]; then
  level=0
fi

if (( level >= 85 )); then
  icon="󰃠"
elif (( level >= 60 )); then
  icon="󰃝"
elif (( level >= 35 )); then
  icon="󰃟"
else
  icon="󰃞"
fi

printf "%s %s%%\n" "$icon" "$level"
