#!/usr/bin/env bash
set -euo pipefail

if ! command -v xset >/dev/null 2>&1; then
  printf "󰪛 \n"
  exit 0
fi

caps_state="$(xset q 2>/dev/null | awk '/Caps Lock:/ {print tolower($4); exit}' || true)"

if [[ "$caps_state" == "on" ]]; then
  printf "󰪛 \n"
else
  printf "󰪛 \n"
fi
