#!/bin/bash
set -euo pipefail

if ! command -v i3lock >/dev/null 2>&1; then
  loginctl lock-session
  exit 0
fi

tmp="${XDG_RUNTIME_DIR:-/tmp}/i3lock-${UID}.png"
cleanup() {
  rm -f "$tmp"
}
trap cleanup EXIT

if command -v import >/dev/null 2>&1 && command -v convert >/dev/null 2>&1; then
  import -window root "$tmp"
  convert "$tmp" -filter Gaussian -blur 0x8 "$tmp"
  i3lock -e -i "$tmp"
else
  i3lock -e
fi
