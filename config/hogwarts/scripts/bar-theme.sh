#!/usr/bin/env bash
# Prints the active Hogwarts theme as a friendly label for the waybar module.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hogwarts"
MODE="$(cat "$STATE_DIR/mode" 2>/dev/null || echo snappy)"
THEME="$(cat "$STATE_DIR/theme" 2>/dev/null || echo gryffindor-dark)"
house="${THEME%-*}"
house="$(printf '%s' "$house" | cut -c1 | tr '[:lower:]' '[:upper:]')$(printf '%s' "$house" | cut -c2-)"
icon="✦"
printf '%s %s' "$house" "$icon"
