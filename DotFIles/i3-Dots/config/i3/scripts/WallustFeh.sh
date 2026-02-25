#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_PATH=""
SKIP_REFRESH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-refresh)
      SKIP_REFRESH=1
      shift
      ;;
    *)
      WALLPAPER_PATH="$1"
      shift
      ;;
  esac
done

extract_wallpaper_from_fehbg() {
  local fehbg_file="${HOME}/.fehbg"
  [[ -f "$fehbg_file" ]] || return 0
  awk -F"'" '/feh .*--bg-/ {print $2; exit}' "$fehbg_file"
}

run_wallust_with_config() {
  local cfg="$1"
  if wallust run --help 2>&1 | grep -q -E '(^|[[:space:]])-c([,[:space:]]|$)|--config'; then
    wallust run -s -c "$cfg" "$WALLPAPER_PATH" >/dev/null 2>&1 || true
  else
    WALLUST_CONFIG="$cfg" wallust run -s "$WALLPAPER_PATH" >/dev/null 2>&1 || true
  fi
}

wait_for_templates() {
  local max_tries=50
  local delay_s=0.1
  local files=("$@")
  local i

  for ((i = 1; i <= max_tries; i++)); do
    local all_ready=1
    local f
    for f in "${files[@]}"; do
      [[ -s "$f" ]] || {
        all_ready=0
        break
      }
    done
    [[ $all_ready -eq 1 ]] && return 0
    sleep "$delay_s"
  done
  return 1
}

if [[ -z "$WALLPAPER_PATH" ]]; then
  WALLPAPER_PATH="$(extract_wallpaper_from_fehbg)"
fi

if [[ -z "$WALLPAPER_PATH" ]]; then
  WALLPAPER_PATH="${HOME}/Pictures/wallpapers/wallpaper.jpg"
fi

if [[ ! -f "$WALLPAPER_PATH" ]]; then
  printf '%s\n' "Wallpaper not found: $WALLPAPER_PATH" >&2
  exit 1
fi

if command -v feh >/dev/null 2>&1; then
  feh --no-fehbg --bg-fill "$WALLPAPER_PATH" >/dev/null 2>&1 || true
fi

ln -sf "$WALLPAPER_PATH" "${HOME}/.config/rofi/.current_wallpaper" || true

if command -v wallust >/dev/null 2>&1; then
  wallust run -s "$WALLPAPER_PATH" >/dev/null 2>&1 || true
fi

kitty_wallust_theme="${HOME}/.config/kitty/kitty-themes/01-Wallust.conf"
wait_targets=("${HOME}/.config/rofi/wallust/colors-rofi.rasi")
if [[ -f "${HOME}/.config/wallust/wallust-kitty.toml" ]] && command -v wallust >/dev/null 2>&1; then
  run_wallust_with_config "${HOME}/.config/wallust/wallust-kitty.toml"
  wait_targets+=("$kitty_wallust_theme")
fi

wait_for_templates "${wait_targets[@]}" || true

if command -v kitty >/dev/null 2>&1 && [[ -s "$kitty_wallust_theme" ]]; then
  kitty @ load-config >/dev/null 2>&1 || true
  kitty @ set-colors --all --configured "$kitty_wallust_theme" >/dev/null 2>&1 || true
fi

if [[ "$SKIP_REFRESH" -eq 0 ]] && [[ -x "${HOME}/.config/i3/scripts/Refresh.sh" ]]; then
  "${HOME}/.config/i3/scripts/Refresh.sh" >/dev/null 2>&1 || true
fi
