#!/usr/bin/env bash
# ============================================================================
#  wallpaper.sh — Rofi wallpaper / theme picker
#  Lists every wallpaper in the wallpaper dir; picking one switches to the
#  Hogwarts theme whose palette references it (full live re-skin).
# ============================================================================
set -euo pipefail
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
HW="$CONFIG_DIR/hogwarts/scripts"
WALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hogwarts/wallpapers"
theme="$CONFIG_DIR/rofi/menu.rasi"

# wallpaper-filename -> theme name (from palettes.conf)
theme_for_wall() {
  awk -v w="$1" '
    /^\[/ { cur=$0; sub(/^\[/,"",cur); sub(/\]$/,"",cur) }
    $1 ~ /^WALLPAPER/ { v=$3; sub(/^[ \t]+/,"",v); sub(/[ \t]+$/,"",v); if (v==w) print cur }
  ' "$CONFIG_DIR/hogwarts/palettes.conf" | head -1
}

mapfile -t walls < <(cd "$WALL_DIR" 2>/dev/null && ls -1 *.png 2>/dev/null | sort)
[ ${#walls[@]} -eq 0 ] && { notify-send -u critical "No wallpapers in $WALL_DIR"; exit 0; }

# Build pretty labels: "Gryffindor  ☾" / "Slytherin ☀"
lines=()
declare -A label_to_wall
for w in "${walls[@]}"; do
  name="${w%.png}"
  house="${name%-*}"; house="$(printf '%s' "${house:0:1}" | tr a-z A-Z)${name:1}"
  case "$name" in *-light) icon="☀";; *) icon="☾";; esac
  [ "$name" = "${name%-light}" ] && house="${name%-*}"; house="$(printf '%s' "${name:0:1}" | tr a-z A-Z)${name:1}"
  lbl="$name  $icon"
  lines+=("$lbl")
  label_to_wall["$lbl"]="$w"
done

choice=$(printf '%s\n' "${lines[@]}" | rofi -dmenu -i -no-custom \
  -theme "$theme" -p "Wallpaper" \
  -theme-str 'window { width: 360px; } listview { lines: 8; }' 2>/dev/null || true)

[ -z "$choice" ] && exit 0
w="${label_to_wall[$choice]}"
t="$(theme_for_wall "$w")"
[ -n "$t" ] && "$HW/set-theme.sh" "$t"
