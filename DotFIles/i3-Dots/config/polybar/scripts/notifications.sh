#!/usr/bin/env bash
set -euo pipefail

status() {
  if ! command -v dunstctl >/dev/null 2>&1; then
    printf "\n"
    return
  fi

  local paused waiting icon
  paused="$(dunstctl is-paused 2>/dev/null || echo false)"
  waiting="$(dunstctl count waiting 2>/dev/null || echo 0)"
  waiting="${waiting:-0}"

  if [[ "$paused" == "true" ]]; then
    icon=""
  else
    icon=""
  fi

  if [[ "$waiting" =~ ^[0-9]+$ ]] && (( waiting > 0 )); then
    printf "%s %s\n" "$icon" "$waiting"
  else
    printf "%s\n" "$icon"
  fi
}

toggle() {
  command -v dunstctl >/dev/null 2>&1 || exit 0
  dunstctl set-paused toggle >/dev/null 2>&1 || true
}

pop() {
  command -v dunstctl >/dev/null 2>&1 || exit 0
  dunstctl history-pop >/dev/null 2>&1 || true
}

clear() {
  command -v dunstctl >/dev/null 2>&1 || exit 0
  dunstctl close-all >/dev/null 2>&1 || true
}

case "${1:-status}" in
toggle) toggle ;;
pop) pop ;;
clear) clear ;;
status) status ;;
*) status ;;
esac
