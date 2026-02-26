#!/usr/bin/env bash
set -euo pipefail

battery_path=""
for candidate in /sys/class/power_supply/BAT*; do
  if [[ -d "$candidate" ]]; then
    battery_path="$candidate"
    break
  fi
done

if [[ -z "$battery_path" ]]; then
  printf "󰚥 AC\n"
  exit 0
fi

capacity="$(cat "${battery_path}/capacity" 2>/dev/null || echo 0)"
status="$(cat "${battery_path}/status" 2>/dev/null || echo Unknown)"
if ! [[ "$capacity" =~ ^[0-9]+$ ]]; then
  capacity=0
fi

if [[ "$status" == "Charging" ]]; then
  icon=""
elif (( capacity >= 95 )); then
  icon="󰁹"
elif (( capacity >= 80 )); then
  icon="󰂂"
elif (( capacity >= 60 )); then
  icon="󰂀"
elif (( capacity >= 40 )); then
  icon="󰁾"
elif (( capacity >= 20 )); then
  icon="󰁻"
else
  icon="󰂎"
fi

printf "%s %s%%\n" "$icon" "$capacity"
