#!/bin/bash
set -euo pipefail

run_once() {
  local cmd="$1"
  shift || true
  pgrep -u "$USER" -x "$cmd" >/dev/null 2>&1 || "$cmd" "$@" &
}

run_once dunst
run_once nm-applet

# Polkit agent
if [ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
  pgrep -u "$USER" -f polkit-gnome-authentication-agent-1 >/dev/null 2>&1 || \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
fi

# Compositor
if command -v picom >/dev/null 2>&1; then
  picom --config "$HOME/.config/picom/picom.conf" --experimental-backends &
fi

# Wallpaper (optional)
WALL="$HOME/Pictures/wallpapers/wallpaper.jpg"
if command -v feh >/dev/null 2>&1 && [ -f "$WALL" ]; then
  feh --no-fehbg --bg-fill "$WALL" &
fi

# Polybar
if [ -x "$HOME/.config/polybar/launch.sh" ]; then
  "$HOME/.config/polybar/launch.sh" &
fi

# Locking / idle
if command -v xss-lock >/dev/null 2>&1; then
  pgrep -u "$USER" -x xss-lock >/dev/null 2>&1 || \
    xss-lock --transfer-sleep-lock -- "$HOME/.config/i3/scripts/lock.sh" &
fi

if command -v xidlehook >/dev/null 2>&1; then
  pgrep -u "$USER" -x xidlehook >/dev/null 2>&1 || \
    xidlehook --not-when-fullscreen --not-when-audio \
      --timer 600 "$HOME/.config/i3/scripts/lock.sh" "" \
      --timer 1800 "systemctl suspend" "" &
fi
