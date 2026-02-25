#!/usr/bin/env bash
set -euo pipefail

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "${HOME}/Pictures")"
WALLPAPER_BASE_PATH="${PICTURES_DIR}/wallpapers/Dynamic-Wallpapers"
DARK_WALLPAPERS="${WALLPAPER_BASE_PATH}/Dark"
LIGHT_WALLPAPERS="${WALLPAPER_BASE_PATH}/Light"
THEME_MODE_CACHE="${HOME}/.cache/.theme_mode"
WALLUST_CONFIG="${HOME}/.config/wallust/wallust.toml"
WALLUST_FEH="${HOME}/.config/i3/scripts/WallustFeh.sh"
NOTIF_ICON="${HOME}/.config/swaync/images/bell.png"

pick_random_wallpaper() {
  local dir="$1"
  local wallpapers=()

  [[ -d "$dir" ]] || return 1
  mapfile -d '' wallpapers < <(
    find -L "$dir" -type f \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
      -print0 2>/dev/null
  )
  [[ ${#wallpapers[@]} -gt 0 ]] || return 1
  printf '%s' "${wallpapers[RANDOM % ${#wallpapers[@]}]}"
}

set_mode_palette() {
  local palette="$1"
  [[ -f "$WALLUST_CONFIG" ]] || return 0
  sed -i -E "s|^palette[[:space:]]*=.*$|palette = \"${palette}\"|" "$WALLUST_CONFIG" || true
}

set_gtk_color_scheme() {
  local mode="$1"
  command -v gsettings >/dev/null 2>&1 || return 0

  if [[ "$mode" == "Dark" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" >/dev/null 2>&1 || true
  else
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light" >/dev/null 2>&1 || true
  fi
}

current_mode="Dark"
if [[ -f "$THEME_MODE_CACHE" ]]; then
  current_mode="$(<"$THEME_MODE_CACHE")"
fi

if [[ "$current_mode" == "Light" ]]; then
  next_mode="Dark"
  wallpaper_dir="$DARK_WALLPAPERS"
  next_palette="dark16"
  rofi_background="rgba(0,0,0,0.7);"
else
  next_mode="Light"
  wallpaper_dir="$LIGHT_WALLPAPERS"
  next_palette="light16"
  rofi_background="rgba(255,255,255,0.9);"
fi

set_mode_palette "$next_palette"
set_gtk_color_scheme "$next_mode"

next_wallpaper=""
if next_wallpaper="$(pick_random_wallpaper "$wallpaper_dir")"; then
  :
fi

if [[ -x "$WALLUST_FEH" ]]; then
  if [[ -n "$next_wallpaper" ]]; then
    "$WALLUST_FEH" "$next_wallpaper" || true
  else
    "$WALLUST_FEH" || true
  fi
fi

ROFI_COLORS="${HOME}/.config/rofi/wallust/colors-rofi.rasi"
if [[ -f "$ROFI_COLORS" ]]; then
  sed -i -E "s|^(\s*background:\s*).*$|\1${rofi_background}|" "$ROFI_COLORS" || true
fi

echo "$next_mode" >"$THEME_MODE_CACHE"

if [[ -x "${HOME}/.config/i3/scripts/Refresh.sh" ]]; then
  "${HOME}/.config/i3/scripts/Refresh.sh" >/dev/null 2>&1 || true
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send -u low -i "$NOTIF_ICON" "Themes switched to:" "${next_mode} mode"
fi
