#!/usr/bin/env bash
set -euo pipefail

updates_count() {
  if command -v checkupdates >/dev/null 2>&1; then
    checkupdates 2>/dev/null | wc -l | awk '{print $1}'
    return
  fi
  printf "0\n"
}

status() {
  local count
  count="$(updates_count)"
  if (( count > 0 )); then
    printf " %s\n" "$count"
  else
    printf " 0\n"
  fi
}

notify() {
  local count
  count="$(updates_count)"
  if command -v notify-send >/dev/null 2>&1; then
    if (( count > 0 )); then
      notify-send -u low "System updates" "${count} package updates available."
    else
      notify-send -u low "System updates" "System is up to date."
    fi
  fi
}

case "${1:-status}" in
notify) notify ;;
status) status ;;
*) status ;;
esac
