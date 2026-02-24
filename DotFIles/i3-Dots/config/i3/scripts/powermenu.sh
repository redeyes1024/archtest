#!/bin/bash
set -euo pipefail

if ! command -v rofi >/dev/null 2>&1; then
  exit 1
fi

choice="$(printf "lock\nlogout\nsuspend\nreboot\nshutdown\n" | rofi -dmenu -i -p power)"

case "$choice" in
  lock)
    "$HOME/.config/i3/scripts/lock.sh"
    ;;
  logout)
    i3-msg exit
    ;;
  suspend)
    "$HOME/.config/i3/scripts/lock.sh" || true
    systemctl suspend
    ;;
  reboot)
    systemctl reboot
    ;;
  shutdown)
    systemctl poweroff
    ;;
  *)
    exit 0
    ;;
esac
