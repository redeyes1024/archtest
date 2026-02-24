#!/bin/bash
# Backwards-compat wrapper.
# This repo has been migrated from Hyprland to i3wm/Xorg.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "[NOTE] '01-hypr-pkgs.sh' is deprecated; running i3 package installer instead..."
exec "$SCRIPT_DIR/01-i3-pkgs.sh"
