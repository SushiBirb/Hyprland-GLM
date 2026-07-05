#!/usr/bin/env bash
# ============================================================================
#  Hogwarts Rice — set-theme.sh
# ----------------------------------------------------------------------------
#  Switches the active Hogwarts theme or toggles the animation/blur preset.
#  Used by the Rofi settings menu.
#
#    set-theme.sh <theme>      # one of the 8 sections in palettes.conf
#    set-theme.sh --mode       # toggle snappy <-> whimsy
#    set-theme.sh --list       # print all available themes, one per line
# ============================================================================
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hogwarts"
HW_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hogwarts"
mkdir -p "$STATE_DIR"

apply() { "$HW_DIR/scripts/apply-theme.sh"; }

themes() {
  grep -oE '^\s*\[[^]]+\]' "$HW_DIR/palettes.conf" | tr -d '[] ' | grep -v '^$'
}

case "${1:-}" in
  --list)
    themes
    ;;
  --mode)
    cur="$(cat "$STATE_DIR/mode" 2>/dev/null || echo snappy)"
    if [ "$cur" = "whimsy" ]; then new="snappy"; else new="whimsy"; fi
    echo "$new" > "$STATE_DIR/mode"
    notify-send -u low -t 1600 "Hogwarts" "Animation preset: $new" 2>/dev/null || true
    apply
    ;;
  --set-mode)
    [ -z "${2:-}" ] && { echo "usage: set-theme.sh --set-mode <snappy|whimsy>" >&2; exit 2; }
    echo "$2" > "$STATE_DIR/mode"
    apply
    ;;
  --mode-get)
    cat "$STATE_DIR/mode" 2>/dev/null || echo snappy
    ;;
  --blur)
    # Toggle Hyprland window blur at runtime
    if hyprctl getoption decoration:blur:enabled -j 2>/dev/null | grep -q '"int":1'; then
      hyprctl keyword decoration:blur:enabled false >/dev/null 2>&1
      notify-send -u low -t 1400 "Hogwarts" "Window blur: off" 2>/dev/null || true
    else
      hyprctl keyword decoration:blur:enabled true >/dev/null 2>&1
      notify-send -u low -t 1400 "Hogwarts" "Window blur: on" 2>/dev/null || true
    fi
    ;;
  "")
    echo "usage: set-theme.sh <theme|--mode|--mode-get|--blur|--list>" >&2
    exit 2
    ;;
  *)
    theme="$1"
    if ! themes | grep -qx "$theme"; then
      echo "set-theme: unknown theme '$theme'" >&2
      echo "available:" >&2; themes | sed 's/^/  /' >&2
      exit 1
    fi
    echo "$theme" > "$STATE_DIR/theme"
    notify-send -u low -t 1600 "Hogwarts" "Theme: ${theme^^}" 2>/dev/null || true
    apply
    ;;
esac
