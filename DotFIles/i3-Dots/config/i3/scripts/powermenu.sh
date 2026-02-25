#!/bin/bash
set -euo pipefail

if ! command -v rofi >/dev/null 2>&1; then
  echo "powermenu requires rofi." >&2
  exit 1
fi

lock_screen() {
  if [ -x "$HOME/.config/i3/scripts/lock.sh" ]; then
    "$HOME/.config/i3/scripts/lock.sh"
  else
    loginctl lock-session
  fi
}

choice="$(printf "lock\nlogout\nsuspend\nreboot\nshutdown\n" | rofi -dmenu -i -p "power")"

case "$choice" in
  lock)
    lock_screen
    ;;
  logout)
    i3-msg exit
    ;;
  suspend)
    lock_screen || true
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
