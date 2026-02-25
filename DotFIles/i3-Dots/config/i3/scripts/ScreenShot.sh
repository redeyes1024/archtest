#!/usr/bin/env bash
set -u
set -o pipefail

timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
pictures_dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
shot_dir="${pictures_dir}/Screenshots"
shot_file="Screenshot_${timestamp}_${RANDOM}.png"
shot_path="${shot_dir}/${shot_file}"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low -i camera-photo "$1" "$2"
  fi
}

countdown() {
  local seconds="$1"
  local sec
  for ((sec = seconds; sec > 0; sec--)); do
    notify "Taking screenshot" "in ${sec} second(s)"
    sleep 1
  done
}

copy_image_to_clipboard() {
  local image_path="$1"
  if command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -t image/png -i "$image_path" >/dev/null 2>&1 || true
  fi
}

save_result() {
  local image_path="$1"

  if [[ -s "$image_path" ]]; then
    copy_image_to_clipboard "$image_path"
    notify "Screenshot saved" "$image_path"
    printf '%s\n' "$image_path"
    return 0
  fi

  rm -f "$image_path"
  notify "Screenshot canceled" "No file was captured."
  return 1
}

shot_full() {
  if command -v maim >/dev/null 2>&1; then
    maim "$shot_path"
    return $?
  fi

  if command -v flameshot >/dev/null 2>&1; then
    flameshot full -p "$shot_path"
    return $?
  fi

  echo "Screenshot failed: install maim or flameshot." >&2
  return 1
}

shot_area() {
  if command -v flameshot >/dev/null 2>&1; then
    flameshot gui -p "$shot_path"
    return $?
  fi

  if command -v maim >/dev/null 2>&1 && command -v slop >/dev/null 2>&1; then
    maim -s "$shot_path"
    return $?
  fi

  echo "Area screenshot failed: install flameshot, or maim with slop." >&2
  return 1
}

shot_active() {
  if command -v maim >/dev/null 2>&1 && command -v xdotool >/dev/null 2>&1; then
    local window_id
    window_id="$(xdotool getactivewindow 2>/dev/null || true)"
    if [[ -n "$window_id" ]]; then
      maim -i "$window_id" "$shot_path"
      return $?
    fi
  fi

  # Fallback for systems where maim+xdotool active-window capture is unavailable.
  shot_area
}

capture_and_report() {
  local capture_fn="$1"
  if "$capture_fn"; then
    save_result "$shot_path"
    return $?
  fi

  rm -f "$shot_path"
  notify "Screenshot canceled" "No file was captured."
  return 1
}

usage() {
  echo "Available options: --now --in5 --in10 --win --area --active"
}

mkdir -p "$shot_dir"

case "${1:-}" in
  --now)
    capture_and_report shot_full
    ;;
  --in5)
    countdown 5
    capture_and_report shot_full
    ;;
  --in10)
    countdown 10
    capture_and_report shot_full
    ;;
  --win|--active)
    capture_and_report shot_active
    ;;
  --area)
    capture_and_report shot_area
    ;;
  *)
    usage
    exit 1
    ;;
esac
