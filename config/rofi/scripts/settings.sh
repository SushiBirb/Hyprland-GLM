#!/usr/bin/env bash
# ============================================================================
#  settings.sh — Hogwarts "Settings Menu" (Rofi)
# ----------------------------------------------------------------------------
#  Features (bound to the Waybar house badge; also SUPER+SHIFT+/):
#    • Switch between the 8 Hogwarts themes (live reload of Waybar, Hyprland,
#      Kitty, Rofi, Dunst, Zen Browser, wallpaper).
#    • Toggle "Whimsy" heavy animations on/off.
#    • Toggle window blur on/off.
#    • View all current keybindings (opens keybinds.sh).
#    • Add a custom keybinding (guided prompts -> written to custom keybinds).
# ============================================================================
set -euo pipefail
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hogwarts"
HW="$CONFIG_DIR/hogwarts/scripts"
theme="$CONFIG_DIR/rofi/menu.rasi"
CUSTOM_KB="$CONFIG_DIR/hypr/custom-keybinds.conf"

rofi_menu() { # prompt  stdin
  rofi -dmenu -i -no-custom -theme "$theme" -p "$1" "${@:2}" 2>/dev/null || true
}

current_theme()  { cat "$STATE_DIR/theme" 2>/dev/null || echo gryffindor-dark; }
current_mode()   { "$HW/set-theme.sh" --mode-get 2>/dev/null || echo snappy; }
blur_state()     { hyprctl getoption decoration:blur:enabled -j 2>/dev/null | grep -q '"int":1' && echo "on" || echo "off"; }

# ---------------------------------------------------------------- main menu ---
main() {
  cur_t="$(current_theme)"; cur_m="$(current_mode)"; cur_b="$(blur_state)"
  m_mode="✦  Whimsy animations:  $cur_m"
  m_blur="❖  Window blur:  $cur_b"
  choice=$( {
    echo "⌂  House themes  ($cur_t)"
    echo "$m_mode"
    echo "$m_blur"
    echo "⌨  View all keybindings"
    echo "➕ Add a custom keybinding"
    echo "↻  Reload current theme"
  } | rofi_menu "Settings" -theme-str 'window { width: 460px; } listview { lines: 6; }')

  case "$choice" in
    "⌂ "*) theme_menu ;;
    *"Whimsy animations"*) "$HW/set-theme.sh" --mode ;;
    *"Window blur"*)       "$HW/set-theme.sh" --blur ;;
    *View*keybindings)     "$CONFIG_DIR/rofi/scripts/keybinds.sh" ;;
    *custom*keybinding*|*Add*) add_keybind ;;
    *Reload*)              "$HW/apply-theme.sh" ;;
    *) ;;
  esac
}

# ------------------------------------------------------------- theme submenu --
theme_menu() {
  # Group the 8 themes by house for a tidy list.
  mapfile -t all < <("$HW/set-theme.sh" --list)
  lines=()
  declare -A label
  for t in "${all[@]}"; do
    house="${t%-*}"; mode="${t##*-}"
    h="$(printf '%s' "$house" | cut -c1 | tr a-z A-Z)$(printf '%s' "$house" | cut -c2-)"
    icon=$([ "$mode" = dark ] && echo "☾" || echo "☀")
    lines+=("$h  $icon   ($t)")
  done
  choice=$(printf '%s\n' "${lines[@]}" | rofi_menu "Choose a house theme" \
            -theme-str 'window { width: 460px; } listview { lines: 8; }')
  # extract the (theme-id) token
  picked="$(printf '%s' "$choice" | grep -oE '\([^)]+\)' | tr -d '()')"
  [ -n "$picked" ] && "$HW/set-theme.sh" "$picked"
}

# ---------------------------------------------------------- add a keybinding ---
add_keybind() {
  # 1) the key combo, e.g. SUPER+SHIFT+P
  keys=$(rofi -dmenu -i -theme "$theme" -p "Keys (e.g. SUPER+SHIFT+P)" \
          -theme-str 'window { width: 460px; } entry { placeholder: "SUPER+SHIFT+P"; }' 2>/dev/null || true)
  [ -z "$keys" ] && return
  # 2) the command to run
  cmd=$(rofi -dmenu -i -theme "$theme" -p "Command to run" \
          -theme-str 'window { width: 520px; } entry { placeholder: "kitty -e htop"; }' 2>/dev/null || true)
  [ -z "$cmd" ] && return
  # 3) optional description
  desc=$(rofi -dmenu -i -theme "$theme" -p "Description (optional)" \
          -theme-str 'window { width: 460px; }' 2>/dev/null || true)

  IFS='+' read -ra modarr <<<"$keys"
  key="${modarr[-1]}"; unset 'modarr[-1]'
  mods=$(IFS=+; printf '%s' "${modarr[*]}")
  echo "# ${desc:-custom}" >> "$CUSTOM_KB"
  echo "bind = ${mods}, ${key}, exec, ${cmd}  # ${desc:-custom}" >> "$CUSTOM_KB"
  hyprctl reload 2>/dev/null || true
  notify-send -u low -t 2000 "Hogwarts" "Keybind added: ${keys}" 2>/dev/null || true
}

main
