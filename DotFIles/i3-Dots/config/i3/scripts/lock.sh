#!/bin/bash
set -euo pipefail

tmp="${XDG_RUNTIME_DIR:-/tmp}/i3lock-${UID}.png"

if command -v import >/dev/null 2>&1 && command -v convert >/dev/null 2>&1; then
  import -window root "$tmp"
  convert "$tmp" -filter Gaussian -blur 0x8 "$tmp"
  i3lock -e -i "$tmp"
  rm -f "$tmp"
else
  i3lock -e
fi
