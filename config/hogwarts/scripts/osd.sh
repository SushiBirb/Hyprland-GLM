#!/usr/bin/env bash
# ============================================================================
#  osd.sh — on-screen display helper (volume / brightness / mute)
#  Writes a 0-100 value to the wob FIFO so an OSD progress bar appears.
#  Usage:  osd.sh vol-up | vol-down | mute | mic-mute | bright-up | bright-down
# ============================================================================
WOB="${WOB_FIFO:-/tmp/wob.sock}"

show() { # value
  [ -p "$WOB" ] || return 0
  printf '%s\n' "$1" > "$WOB" 2>/dev/null || true
}

cur_vol() { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%d", $2*100}'; }
cur_bright() { brightnessctl -m 2>/dev/null | awk -F, '{gsub("%","",$2); print $2}'; }

case "${1:-}" in
  vol-up)     wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+ ; show "$(cur_vol)" ;;
  vol-down)   wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%- ; show "$(cur_vol)" ;;
  mute)       wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ; show "$(cur_vol)" ;;
  mic-mute)   wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ; show "$(cur_vol)" ;;
  bright-up)   brightnessctl set +5% ; show "$(cur_bright)" ;;
  bright-down) brightnessctl set 5%-  ; show "$(cur_bright)" ;;
  *) echo "usage: osd.sh vol-up|vol-down|mute|mic-mute|bright-up|bright-down" >&2; exit 2 ;;
esac
