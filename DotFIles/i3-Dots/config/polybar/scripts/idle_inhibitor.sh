#!/usr/bin/env bash
set -euo pipefail

dpms_state() {
  xset q 2>/dev/null | awk '/DPMS is/ {print $3; exit}' || echo "Enabled"
}

status() {
  if ! command -v xset >/dev/null 2>&1; then
    printf "\n"
    return
  fi

  if [[ "$(dpms_state)" == "Enabled" ]]; then
    printf "\n"
  else
    printf "\n"
  fi
}

toggle() {
  command -v xset >/dev/null 2>&1 || exit 0

  if [[ "$(dpms_state)" == "Enabled" ]]; then
    xset s off -dpms
  else
    xset s on +dpms
  fi
}

case "${1:-status}" in
toggle) toggle ;;
status) status ;;
*) status ;;
esac
