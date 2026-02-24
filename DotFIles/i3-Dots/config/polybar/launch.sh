#!/bin/bash
set -euo pipefail

killall -q polybar || true

while pgrep -u "$UID" -x polybar >/dev/null 2>&1; do
  sleep 0.2
done

polybar main &
