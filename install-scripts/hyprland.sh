#!/bin/bash
# Backwards-compat wrapper.
# This repo has been migrated from Hyprland to i3wm/Xorg.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "[NOTE] 'hyprland.sh' is deprecated; running i3wm installer instead..."
exec "$SCRIPT_DIR/i3wm.sh"