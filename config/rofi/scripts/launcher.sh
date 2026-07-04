#!/usr/bin/env bash
# ============================================================================
#  launcher.sh — Rofi application launcher (drun + run fallback)
# ============================================================================
set -euo pipefail
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
theme="$CONFIG_DIR/rofi/current.rasi"
[ -f "$theme" ] || theme="$CONFIG_DIR/rofi/menu.rasi"

if ! rofi -show drun -theme "$theme" \
     -drun-match-fields 'name,generic,exec,categories,keywords' \
     -show-icons -matching fuzzy 2>/dev/null; then
    rofi -show run -theme "$theme" -show-icons
fi
