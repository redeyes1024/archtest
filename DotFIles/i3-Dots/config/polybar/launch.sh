#!/bin/bash
set -euo pipefail

killall -q polybar || true

while pgrep -u "$UID" -x polybar >/dev/null 2>&1; do
  sleep 0.2
done

if ! command -v polybar >/dev/null 2>&1; then
  echo "polybar is not installed." >&2
  exit 1
fi

mapfile -t monitors < <(polybar --list-monitors 2>/dev/null | cut -d: -f1 || true)

if [[ "${#monitors[@]}" -eq 0 ]]; then
  polybar main &
  polybar aux &
else
  for monitor in "${monitors[@]}"; do
    MONITOR="$monitor" polybar main &
    MONITOR="$monitor" polybar aux &
  done
fi
