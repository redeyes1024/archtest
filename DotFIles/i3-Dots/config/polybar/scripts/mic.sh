#!/usr/bin/env bash
set -euo pipefail

if ! command -v pamixer >/dev/null 2>&1; then
  printf "\n"
  exit 0
fi

muted="$(pamixer --default-source --get-mute 2>/dev/null || echo true)"
level="$(pamixer --default-source --get-volume 2>/dev/null || echo 0)"

if [[ "$muted" == "true" || "$level" -eq 0 ]]; then
  printf "\n"
else
  printf " %s%%\n" "$level"
fi
