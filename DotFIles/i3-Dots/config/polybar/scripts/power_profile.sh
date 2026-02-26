#!/usr/bin/env bash
set -euo pipefail

current_profile() {
  powerprofilesctl get 2>/dev/null || echo "balanced"
}

profile_icon() {
  case "$1" in
  performance) printf "" ;;
  balanced) printf "" ;;
  power-saver) printf "" ;;
  *) printf "" ;;
  esac
}

status() {
  if ! command -v powerprofilesctl >/dev/null 2>&1; then
    printf " n/a\n"
    return
  fi

  local profile
  profile="$(current_profile)"
  printf "%s %s\n" "$(profile_icon "$profile")" "$profile"
}

toggle() {
  command -v powerprofilesctl >/dev/null 2>&1 || exit 0

  local current next
  current="$(current_profile)"

  case "$current" in
  power-saver) next="balanced" ;;
  balanced) next="performance" ;;
  performance) next="power-saver" ;;
  *) next="balanced" ;;
  esac

  powerprofilesctl set "$next" >/dev/null 2>&1 || true
}

case "${1:-status}" in
toggle) toggle ;;
status) status ;;
*) status ;;
esac
