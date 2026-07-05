#!/usr/bin/env bash
# ============================================================================
#  idle-inhibit.sh — "keep awake" toggle.
#  Hyprland's idle is driven by hypridle (a Wayland idle daemon), which
#  systemd-inhibit cannot reach.  So we toggle hypridle itself: pausing it
#  prevents auto-dim / lock / suspend; resuming restores normal idle rules.
#    idle-inhibit.sh          toggle on/off
#    idle-inhibit.sh on|off|status
# ============================================================================
STATEF="/tmp/hogwarts-keep-awake"

is_on() { [ -f "$STATEF" ]; }

resume_hypridle() {
  # Only restart if nothing is running.
  if ! pgrep -x hypridle >/dev/null 2>&1; then
    command -v hypridle >/dev/null 2>&1 && nohup hypridle >/dev/null 2>&1 &
    disown 2>/dev/null || true
  fi
}

pause_hypridle() {
  pkill -x hypridle 2>/dev/null || true
}

case "${1:-toggle}" in
  on)
    pause_hypridle
    touch "$STATEF"
    ;;
  off)
    rm -f "$STATEF"
    resume_hypridle
    ;;
  status)
    is_on && echo on || echo off
    ;;
  toggle)
    if is_on; then rm -f "$STATEF"; resume_hypridle; else pause_hypridle; touch "$STATEF"; fi
    ;;
  *)
    echo "usage: idle-inhibit.sh [on|off|status|toggle]" >&2
    exit 2
    ;;
esac
