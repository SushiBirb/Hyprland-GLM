#!/usr/bin/env bash
# ============================================================================
#  Hogwarts Rice — apply-theme.sh
# ----------------------------------------------------------------------------
#  Renders every app config from the active palette + reloads each running
#  component so the whole desktop re-skins live.
#
#  State (under ${XDG_STATE_HOME:-$HOME/.local/state}/hogwarts/):
#    theme   -> e.g. "gryffindor-dark"   (one of 8 sections in palettes.conf)
#    mode    -> "snappy" | "whimsy"      (animation/blur preset)
#
#  Reads templates from $CONFIG_DIR/hogwarts/templates/ and writes finished
#  configs into the real ~/.config locations.
# ============================================================================
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hogwarts"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hogwarts/rendered"
HW_DIR="$CONFIG_DIR/hogwarts"
WALL_DIR="$HOME/.local/share/hogwarts/wallpapers"

mkdir -p "$STATE_DIR" "$CACHE_DIR" "$WALL_DIR"

THEME="$(cat "$STATE_DIR/theme" 2>/dev/null || echo gryffindor-dark)"
MODE="$(cat "$STATE_DIR/mode" 2>/dev/null || echo snappy)"

PALETTES="$HW_DIR/palettes.conf"
TDIR="$HW_DIR/templates"

log() { printf 'apply-theme: %s\n' "$*" >&2; }

# --- 1. Render every template ------------------------------------------------
render() {
  python3 "$HW_DIR/scripts/render.py" "$PALETTES" "$THEME" "$TDIR" "$CACHE_DIR"
}
render

# --- 2. Distribute rendered files into real config locations -----------------
deploy() { # src_rel  dest_abs
  local src="$CACHE_DIR/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
}

deploy kitty/kitty.conf         "$CONFIG_DIR/kitty/kitty.conf"
deploy waybar/style.css         "$CONFIG_DIR/waybar/style.css"
deploy rofi/theme.rasi          "$CONFIG_DIR/rofi/current.rasi"
deploy rofi/menu.rasi           "$CONFIG_DIR/rofi/menu.rasi"
deploy dunst/dunstrc            "$CONFIG_DIR/dunst/dunstrc"
deploy hypr/colors.conf         "$CONFIG_DIR/hypr/colors.conf"
deploy hypr/colors.lua          "$CONFIG_DIR/hypr/colors.lua"
deploy zen/userChrome.css       "$CONFIG_DIR/zen/chrome/userChrome.css"

# Animation preset is chosen by MODE (snappy vs whimsy), not by colour palette.
ANIM_SRC="$CONFIG_DIR/hypr/animations-${MODE}.conf"
[ -f "$ANIM_SRC" ] || ANIM_SRC="$CONFIG_DIR/hypr/animations-snappy.conf"
cp -f "$ANIM_SRC" "$CONFIG_DIR/hypr/active-animations.conf"

# --- 3. Resolve the wallpaper for this theme ---------------------------------
wallpaper_value() { awk -F= -v t="$THEME" '
  /^\[/ { cur = ($0 ~ "\\[" t "\\]") }
  cur {
    k=$1; sub(/[ \t]+$/,"",k)
    if (k=="WALLPAPER") { v=$2; sub(/^[ \t]+/,"",v); sub(/[ \t]+$/,"",v); print v }
  }
' "$PALETTES" | head -1; }
WALL_NAME="$(wallpaper_value)"
WALL_PATH="$WALL_DIR/${WALL_NAME:-gryffindor.png}"
[ -f "$WALL_PATH" ] || WALL_PATH="$WALL_DIR/gryffindor.png"

# --- 4. Reload each running component ----------------------------------------

# Hyprland — source generated colours + animation preset
if hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

# kitty — live-reload all instances (SIGUSR1 reloads kitty.conf)
if pgrep -x kitty >/dev/null 2>&1; then
  killall -SIGUSR1 kitty 2>/dev/null || true
fi

# waybar — restart so style.css is re-read
if pgrep -x waybar >/dev/null 2>&1; then
  pkill -x waybar 2>/dev/null || true
  ( sleep 0.2; waybar >/dev/null 2>&1 & ) || true
fi

# dunst — reload via SIGHUP, restart if the config path changed
if pgrep -x dunst >/dev/null 2>&1; then
  killall -SIGHUP dunst 2>/dev/null || true
else
  ( dunst >/dev/null 2>&1 & ) || true
fi

# swww (or its maintained fork "awww") wallpaper with a magical grow transition.
SWWW_BIN="$(command -v swww || command -v awww || true)"
SWWW_DAEMON="$(command -v swww-daemon || command -v awww-daemon || true)"
if [ -n "$SWWW_BIN" ] && pgrep -x "$(basename "${SWWW_DAEMON:-swww-daemon}")" >/dev/null 2>&1; then
  "$SWWW_BIN" img "$WALL_PATH" \
    --transition-type grow --transition-pos 0.854,0.854 \
    --transition-duration 1.6 --transition-fps 60 \
    --transition-step 90 >/dev/null 2>&1 || true
fi

# Zen Browser — write userChrome + enable the pref in every profile
if [ -x "$HW_DIR/scripts/zen-theme.sh" ]; then
  "$HW_DIR/scripts/zen-theme.sh" "$WALL_PATH" >/dev/null 2>&1 || true
fi

log "applied theme=$THEME mode=$MODE wallpaper=$WALL_NAME"
