#!/usr/bin/env bash
# ============================================================================
#  recorder.sh — wf-recorder wrapper (screen / region / stop), with audio.
#    recorder.sh start-region | start-screen | stop | menu
# ============================================================================
set -euo pipefail
REC_DIR="${VIDEOS_DIR:-$HOME/Videos/Screencasts}"
mkdir -p "$REC_DIR"
PIDF="/tmp/hogwarts-recorder.pid"
LOG="/tmp/hogwarts-recorder.log"

is_recording() { [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; }

start() { # geometry or empty for fullscreen
  if is_recording; then notify-send -u low -t 1200 "Hogwarts" "Already recording"; return; fi
  local geom="${1:-}"
  local file="$REC_DIR/$(date +%Y%m%d-%H%M%S).mp4"
  local args=(-f "$file" --pixel-format yuv420p)
  # Pick a render node if one exists; wf-recorder otherwise auto-detects.
  local rn; rn="$(ls /dev/dri/renderD12* 2>/dev/null | head -1)"
  [ -n "$rn" ] && args+=(-d "$rn")
  if command -v pactl >/dev/null; then args+=(--audio); fi
  if [ -n "$geom" ]; then args+=(-g "$geom"); fi
  wf-recorder "${args[@]}" >"$LOG" 2>&1 &
  echo $! > "$PIDF"
  # Wait briefly to catch immediate failures.
  sleep 0.4
  if is_recording; then
    notify-send -u low -t 1500 "Hogwarts" "Recording started" 2>/dev/null || true
  else
    notify-send -u critical -t 3000 "Hogwarts" "Recording failed — see $LOG" 2>/dev/null || true
    rm -f "$PIDF"
  fi
}

stop() {
  if ! is_recording; then notify-send -u low -t 1200 "Hogwarts" "Not recording"; return; fi
  local pid; pid="$(cat "$PIDF" 2>/dev/null)"
  kill -INT "$pid" 2>/dev/null || true
  # wf-recorder finalizes on SIGINT; wait for it.
  for _ in $(seq 1 20); do kill -0 "$pid" 2>/dev/null || break; sleep 0.2; done
  rm -f "$PIDF"
  notify-send -u low -t 2000 "Hogwarts" "Recording saved to $REC_DIR" 2>/dev/null || true
}

menu() {
  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
  theme="$CONFIG_DIR/rofi/menu.rasi"
  if is_recording; then
    choice="⏹ Stop recording"
  else
    choice=$(printf '|RF Record fullscreen\n|RF Record region\n' \
      | rofi -dmenu -i -no-custom -theme "$theme" -p "Record" \
        -theme-str 'window { width: 320px; } listview { lines: 2; }' 2>/dev/null | sed 's/^.*RF //')
  fi
  case "$choice" in
    "Record fullscreen") start "" ;;
    "Record region")     start "$(slurp)" ;;
    "Stop recording")    stop ;;
    *) ;;
  esac
}

case "${1:-menu}" in
  start-region) start "$(slurp)" ;;
  start-screen) start "" ;;
  stop)         stop ;;
  menu|"")      menu ;;
  *) echo "usage: recorder.sh [start-region|start-screen|stop|menu]" >&2; exit 2 ;;
esac
