#!/usr/bin/env bash
set -euo pipefail

ROFI_COLORS="${HOME}/.config/rofi/wallust/colors-rofi.rasi"
I3_CONFIG="${HOME}/.config/i3/config"
POLYBAR_CONFIG="${HOME}/.config/polybar/config.ini"
POLYBAR_LAUNCH="${HOME}/.config/polybar/launch.sh"

color_from_rofi() {
  local key="$1"
  [[ -f "$ROFI_COLORS" ]] || return 0
  sed -n "s/^\\s*${key}:\\s*\\(#[0-9A-Fa-f]\\{6\\}\\).*/\\1/p" "$ROFI_COLORS" | head -n1
}

sync_rofi_selection_colors() {
  [[ -f "$ROFI_COLORS" ]] || return 0

  local accent
  accent="$(color_from_rofi color12)"
  [[ -z "$accent" ]] && accent="$(color_from_rofi color13)"
  [[ -z "$accent" ]] && return 0

  sed -i -E "s|^(\s*selected-normal-background:\s*).*$|\1${accent};|" "$ROFI_COLORS" || true
  sed -i -E "s|^(\s*selected-active-background:\s*).*$|\1${accent};|" "$ROFI_COLORS" || true
  sed -i -E "s|^(\s*selected-urgent-background:\s*).*$|\1${accent};|" "$ROFI_COLORS" || true

  sed -i -E "s|^(\s*selected-normal-foreground:\s*).*$|\1#000000;|" "$ROFI_COLORS" || true
  sed -i -E "s|^(\s*selected-active-foreground:\s*).*$|\1#000000;|" "$ROFI_COLORS" || true
  sed -i -E "s|^(\s*selected-urgent-foreground:\s*).*$|\1#000000;|" "$ROFI_COLORS" || true
}

sync_i3_palette() {
  [[ -f "$I3_CONFIG" ]] || return 0

  local focused unfocused surface text urgent
  focused="$(color_from_rofi color12)"
  unfocused="$(color_from_rofi color10)"
  surface="$(color_from_rofi color0)"
  text="$(color_from_rofi color15)"
  urgent="$(color_from_rofi color13)"

  [[ -z "$focused" || -z "$surface" || -z "$text" ]] && return 0
  [[ -z "$unfocused" ]] && unfocused="$focused"
  [[ -z "$urgent" ]] && urgent="$focused"

  sed -i -E "s|^set \\\$focused_accent .*|set \\\$focused_accent ${focused}|" "$I3_CONFIG" || true
  sed -i -E "s|^set \\\$unfocused_accent .*|set \\\$unfocused_accent ${unfocused}|" "$I3_CONFIG" || true
  sed -i -E "s|^set \\\$surface_bg .*|set \\\$surface_bg ${surface}|" "$I3_CONFIG" || true
  sed -i -E "s|^set \\\$text_fg .*|set \\\$text_fg ${text}|" "$I3_CONFIG" || true
  sed -i -E "s|^set \\\$urgent_accent .*|set \\\$urgent_accent ${urgent}|" "$I3_CONFIG" || true
}

sync_polybar_palette() {
  [[ -f "$POLYBAR_CONFIG" ]] || return 0

  local bg fg muted accent
  bg="$(color_from_rofi color0)"
  fg="$(color_from_rofi color15)"
  muted="$(color_from_rofi color8)"
  accent="$(color_from_rofi color12)"

  [[ -z "$bg" || -z "$fg" || -z "$accent" ]] && return 0
  [[ -z "$muted" ]] && muted="$fg"

  sed -i -E "s|^(bg[[:space:]]*=[[:space:]]*).*$|\1${bg}|" "$POLYBAR_CONFIG" || true
  sed -i -E "s|^(fg[[:space:]]*=[[:space:]]*).*$|\1${fg}|" "$POLYBAR_CONFIG" || true
  sed -i -E "s|^(muted[[:space:]]*=[[:space:]]*).*$|\1${muted}|" "$POLYBAR_CONFIG" || true
  sed -i -E "s|^(accent[[:space:]]*=[[:space:]]*).*$|\1${accent}|" "$POLYBAR_CONFIG" || true
}

reload_terminals() {
  if pidof kitty >/dev/null 2>&1; then
    for pid in $(pidof kitty); do
      kill -SIGUSR1 "$pid" 2>/dev/null || true
    done
  fi

  if pidof ghostty >/dev/null 2>&1; then
    for pid in $(pidof ghostty); do
      kill -SIGUSR2 "$pid" 2>/dev/null || true
    done
  fi
}

reload_i3_polybar() {
  if command -v i3-msg >/dev/null 2>&1; then
    i3-msg reload >/dev/null 2>&1 || true
  fi

  if [[ -x "$POLYBAR_LAUNCH" ]]; then
    "$POLYBAR_LAUNCH" >/dev/null 2>&1 || true
  fi
}

sync_rofi_selection_colors
sync_i3_palette
sync_polybar_palette
reload_terminals
reload_i3_polybar
