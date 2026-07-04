#!/usr/bin/env bash
# ============================================================================
#  keybinds.sh — "All current keybind shortcuts" viewer
# ----------------------------------------------------------------------------
#  Parses ~/.config/hypr/keybinds.conf (the illogical-impulse grammar) and
#  shows every shortcut in a Rofi menu.  Bound to SUPER + /.
#  Grammar understood:
#    ##! Section heading      (rendered as a disabled group title)
#    bind = mods,key,disp,params # comment   (real bind)
#    ... # [hidden]           (suppressed)
# ============================================================================
set -euo pipefail
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
KB="$CONFIG_DIR/hypr/keybinds.conf"
theme="$CONFIG_DIR/rofi/menu.rasi"

# Mod prettify: SUPER -> , CTRL -> , ALT -> , SHIFT ->  (Nerd Font glyphs).
prettify() {
  local s="$1"
  s="${s//SUPER/󰘳}"
  s="${s//CTRL/󰢹}"
  s="${s//ALT/󰘵}"
  s="${s//SHIFT/󰘶}"
  s="${s//+/ }"
  printf '%s' "$s"
}

# Build the display list. Format: "  <keys>   description"
mapfile -t rows < <(python3 - "$KB" <<'PY'
import re, sys, unicodedata
path = sys.argv[1]
super_g = lambda k: {
    "killactive":"Close window","exec":"Run","workspace":"Go to workspace",
    "movetoworkspace":"Move window to workspace","movetoworkspacesilent":"Move window silently",
    "togglefloating":"Toggle floating","fullscreen":"Toggle fullscreen","movefocus":"Move focus",
    "swapwindow":"Swap window","togglespecialworkspace":"Toggle special workspace",
    "pin":"Pin window","splitratio":"Resize split","resizeactive":"Resize window",
}.get(k, k.replace("_"," ").capitalize())
try:
    lines = open(path, encoding="utf-8").read().splitlines()
except FileNotFoundError:
    sys.exit(0)
for ln in lines:
    s = ln.strip()
    if s.startswith("##!"):
        print(f"\x1e{ s.lstrip('# !').strip() }")
        continue
    if s.startswith("bind") and "=" in s and "# [hidden]" not in ln:
        body = ln.split("#",1)[0].strip()
        comment = (ln.split("#",1)[1].strip() if "#" in ln else "")
        parts = [p.strip() for p in body.split(",")]
        # form: bind = mods , key , dispatcher , params...
        if len(parts) >= 3:
            mods = parts[0].split("=",1)[1].strip()
            key  = parts[1]
            disp = parts[2]
            if not comment:
                comment = super_g(disp)
            print(f"{mods}+{key}\t{comment}")
PY
)

# Render rows for rofi dmenu (group titles prefixed with NUL-ish marker -> use leading "──").
choice_lines=()
for r in "${rows[@]}"; do
  if [[ "$r" == $'\x1e'* ]]; then
    sec="${r:1}"
    choice_lines+=("── ${sec^^} ──")
  else
    IFS=$'\t' read -r keys desc <<<"$r"
    pkeys="$(prettify "$keys")"
    choice_lines+=("$(printf '%-22s  %s' "$pkeys" "$desc")")
  fi
done

printf '%s\n' "${choice_lines[@]}" | rofi -dmenu -i -no-custom \
  -theme "$theme" \
  -p "Keybindings" \
  -theme-str 'listview { lines: 14; } entry { enabled: false; }' 2>/dev/null || true
