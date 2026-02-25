#!/usr/bin/env bash
# Default xrandr profile: enable connected outputs and place left-to-right.

set -euo pipefail

if ! command -v xrandr >/dev/null 2>&1; then
    echo "xrandr is required for monitor profiles." >&2
    exit 1
fi

mapfile -t connected_outputs < <(xrandr --query | awk '/ connected/ {print $1}')
mapfile -t disconnected_outputs < <(xrandr --query | awk '/ disconnected/ {print $1}')

if [[ ${#connected_outputs[@]} -eq 0 ]]; then
    echo "No connected monitor outputs detected." >&2
    exit 1
fi

primary_output=""
for output in "${connected_outputs[@]}"; do
    if [[ "$output" =~ ^(eDP|LVDS) ]]; then
        primary_output="$output"
        break
    fi
done

if [[ -z "$primary_output" ]]; then
    primary_output="${connected_outputs[0]}"
fi

xrandr --output "$primary_output" --auto --primary

anchor_output="$primary_output"
for output in "${connected_outputs[@]}"; do
    if [[ "$output" == "$primary_output" ]]; then
        continue
    fi
    xrandr --output "$output" --auto --right-of "$anchor_output"
    anchor_output="$output"
done

for output in "${disconnected_outputs[@]}"; do
    xrandr --output "$output" --off
done
