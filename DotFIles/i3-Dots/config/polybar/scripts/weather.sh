#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/polybar"
CACHE_FILE="${CACHE_DIR}/weather"
TTL_SECONDS="${WEATHER_TTL_SECONDS:-900}"
LOCATION="${WEATHER_LOCATION:-}"
USE_CACHE=true

if ! mkdir -p "$CACHE_DIR" 2>/dev/null; then
  CACHE_DIR="${TMPDIR:-/tmp}/polybar-${UID}"
  CACHE_FILE="${CACHE_DIR}/weather"
  if ! mkdir -p "$CACHE_DIR" 2>/dev/null; then
    USE_CACHE=false
  fi
fi

fetch_weather() {
  local url
  if [[ -n "$LOCATION" ]]; then
    url="https://wttr.in/${LOCATION}?format=%c+%t"
  else
    url="https://wttr.in/?format=%c+%t"
  fi
  curl -fsS --max-time 4 "$url" | tr -d '\n'
}

cache_stale() {
  [[ "$USE_CACHE" == "false" ]] && return 0
  [[ ! -f "$CACHE_FILE" ]] && return 0
  local now mtime
  now=$(date +%s)
  mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  (( now - mtime >= TTL_SECONDS ))
}

refresh_cache() {
  command -v curl >/dev/null 2>&1 || return 1
  local weather=""
  weather="$(fetch_weather 2>/dev/null || true)"
  [[ -n "$weather" ]] || return 1
  if [[ "$USE_CACHE" == "true" ]]; then
    printf "%s" "$weather" >"$CACHE_FILE"
  else
    printf "%s\n" "$weather"
  fi
}

if [[ "${1:-}" == "--refresh" ]]; then
  refresh_cache || true
fi

if cache_stale; then
  weather_live="$(refresh_cache 2>/dev/null || true)"
else
  weather_live=""
fi

if [[ "$USE_CACHE" == "true" && -s "$CACHE_FILE" ]]; then
  printf "%s\n" "$(cat "$CACHE_FILE")"
elif [[ -n "${weather_live:-}" ]]; then
  printf "%s\n" "$weather_live"
else
  printf "󰖐 --°C\n"
fi
