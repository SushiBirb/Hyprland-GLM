#!/usr/bin/env bash
# ============================================================================
#  power.sh — Rofi power/session menu
# ============================================================================
set -euo pipefail
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
theme="$CONFIG_DIR/rofi/menu.rasi"

lock="󰌾  Lock"
logout="󰗽  Log out"
suspend="󰤄  Suspend"
hibernate="󰤁  Hibernate"
reboot="󰜉  Reboot"
shutdown="󰐥  Shut down"
cancel="󰜷  Cancel"

choice=$(printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
    "$lock" "$logout" "$suspend" "$hibernate" "$reboot" "$shutdown" "$cancel" \
  | rofi -dmenu -i -no-custom -theme "$theme" -p "Session" \
    -theme-str 'window { width: 340px; } listview { lines: 7; }' 2>/dev/null || true)

case "$choice" in
  "$lock")      loginctl lock-session 2>/dev/null || hyprctl dispatch lock ;;
  "$logout")    hyprctl dispatch exit 2>/dev/null || loginctl terminate-user "$USER" ;;
  "$suspend")   systemctl suspend ;;
  "$hibernate") systemctl hibernate ;;
  "$reboot")    systemctl reboot ;;
  "$shutdown")  systemctl poweroff ;;
  *) ;;
esac
