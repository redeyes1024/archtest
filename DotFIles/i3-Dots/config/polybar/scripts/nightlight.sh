#!/usr/bin/env bash
set -euo pipefail

TEMP="${NIGHTLIGHT_TEMP:-4500}"

status() {
  if command -v gammastep >/dev/null 2>&1; then
    if pgrep -x gammastep >/dev/null 2>&1; then
      printf "󰌵\n"
    else
      printf "󰌶\n"
    fi
    return
  fi

  if command -v redshift >/dev/null 2>&1; then
    if pgrep -x redshift >/dev/null 2>&1; then
      printf "󰌵\n"
    else
      printf "󰌶\n"
    fi
    return
  fi

  printf "󰖔\n"
}

toggle() {
  if command -v gammastep >/dev/null 2>&1; then
    if pgrep -x gammastep >/dev/null 2>&1; then
      pkill -x gammastep || true
    else
      gammastep -O "$TEMP" -P >/dev/null 2>&1 &
    fi
    exit 0
  fi

  if command -v redshift >/dev/null 2>&1; then
    if pgrep -x redshift >/dev/null 2>&1; then
      pkill -x redshift || true
    else
      redshift -O "$TEMP" -P >/dev/null 2>&1 &
    fi
    exit 0
  fi
}

case "${1:-status}" in
toggle) toggle ;;
status) status ;;
*) status ;;
esac
