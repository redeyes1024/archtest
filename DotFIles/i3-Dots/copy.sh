#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

copy_dir() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
}

echo "[INFO] Installing i3 dotfiles..."

# Configs
copy_dir "$SCRIPT_DIR/config/i3" "$HOME/.config/i3"
copy_dir "$SCRIPT_DIR/config/polybar" "$HOME/.config/polybar"
copy_dir "$SCRIPT_DIR/config/rofi" "$HOME/.config/rofi"
copy_dir "$SCRIPT_DIR/config/picom" "$HOME/.config/picom"
copy_dir "$SCRIPT_DIR/config/dunst" "$HOME/.config/dunst"

# Optional: import extra rofi themes/configs from legacy Hyprland-Dots bundle (if present)
LEGACY_ROFI="$SCRIPT_DIR/../Hyprland-Dots/config/rofi"
if [ -d "$LEGACY_ROFI" ]; then
  mkdir -p "$HOME/.config/rofi"

  if [ -d "$LEGACY_ROFI/themes" ]; then
    mkdir -p "$HOME/.config/rofi/themes"
    cp -a "$LEGACY_ROFI/themes/." "$HOME/.config/rofi/themes/"
  fi

  if [ -d "$LEGACY_ROFI/wallust" ]; then
    mkdir -p "$HOME/.config/rofi/wallust"
    cp -a "$LEGACY_ROFI/wallust/." "$HOME/.config/rofi/wallust/"
  fi

  # Copy additional menus (do not overwrite the main config.rasi we ship)
  for f in "$LEGACY_ROFI"/config-*.rasi "$LEGACY_ROFI"/*.list; do
    [ -f "$f" ] || continue
    cp -a "$f" "$HOME/.config/rofi/"
  done
fi

# Home files
if [ -f "$SCRIPT_DIR/home/.xinitrc" ]; then
  if [ ! -f "$HOME/.xinitrc" ]; then
    cp -a "$SCRIPT_DIR/home/.xinitrc" "$HOME/.xinitrc"
    echo "[OK] Installed ~/.xinitrc"
  else
    echo "[NOTE] ~/.xinitrc already exists; leaving it unchanged"
  fi
fi

chmod +x "$HOME/.config/i3/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/polybar/launch.sh" 2>/dev/null || true

echo "[OK] i3 dotfiles installed."
