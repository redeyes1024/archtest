#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEGACY_CONFIG_DIR="$SCRIPT_DIR/../Hyprland-Dots/config"
ASSETS_FASTFETCH_DIR="$SCRIPT_DIR/../../assets/fastfetch"

copy_dir() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
}

copy_component() {
  local component="$1"
  local target_name="${2:-$1}"
  local target_dir="$HOME/.config/$target_name"
  local legacy_src="$LEGACY_CONFIG_DIR/$component"
  local local_src="$SCRIPT_DIR/config/$component"

  # Seed from legacy first, then let i3-Dots override when present.
  if [ -d "$legacy_src" ]; then
    copy_dir "$legacy_src" "$target_dir"
    echo "[OK] Imported legacy $component config"
  fi

  if [ -d "$local_src" ]; then
    copy_dir "$local_src" "$target_dir"
    echo "[OK] Installed i3 $component config"
  fi
}

copy_fastfetch() {
  local target_dir="$HOME/.config/fastfetch"
  local local_src="$SCRIPT_DIR/config/fastfetch"
  local legacy_src="$LEGACY_CONFIG_DIR/fastfetch"

  if [ -d "$legacy_src" ]; then
    copy_dir "$legacy_src" "$target_dir"
    echo "[OK] Imported legacy fastfetch config"
  fi

  if [ -d "$local_src" ]; then
    copy_dir "$local_src" "$target_dir"
    echo "[OK] Installed i3 fastfetch config"
  elif [ -d "$ASSETS_FASTFETCH_DIR" ]; then
    copy_dir "$ASSETS_FASTFETCH_DIR" "$target_dir"
    echo "[OK] Installed fastfetch config from assets"
  fi
}

echo "[INFO] Installing i3 dotfiles..."

# Core i3 configs
copy_dir "$SCRIPT_DIR/config/i3" "$HOME/.config/i3"
copy_dir "$SCRIPT_DIR/config/polybar" "$HOME/.config/polybar"
copy_dir "$SCRIPT_DIR/config/picom" "$HOME/.config/picom"
copy_dir "$SCRIPT_DIR/config/dunst" "$HOME/.config/dunst"

# Rofi: merge full legacy theme/menu collection, then apply i3 defaults.
copy_component "rofi" "rofi"

# Non-WM configs for visual/app parity
copy_component "qt5ct" "qt5ct"
copy_component "qt6ct" "qt6ct"
copy_component "kitty" "kitty"
copy_component "Kvantum" "Kvantum"
copy_component "wallust" "wallust"
copy_component "swaync" "swaync"  # icons/images are reused by i3 helper scripts
copy_component "cava" "cava"
copy_fastfetch

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
