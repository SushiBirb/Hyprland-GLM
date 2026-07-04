#!/usr/bin/env bash
# ============================================================================
#  Hogwarts Rice — zen-theme.sh
# ----------------------------------------------------------------------------
#  Dynamically themes Zen Browser (a Firefox fork) to match the active
#  Hogwarts palette.  Zen honours Firefox's userChrome.css when the legacy
#  pref is enabled, so we drop the rendered stylesheet into every profile's
#  chrome/ directory and flip the pref.
#
#  Called by apply-theme.sh.  The rendered userChrome.css is already at
#  $CONFIG_DIR/zen/chrome/userChrome.css (full of {{ACCENT}} etc. already
#  substituted).  This script only distributes it + sets prefs.
# ============================================================================
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hogwarts"
ZEN_ROOT="$CONFIG_DIR/zen"
RENDERED="$ZEN_ROOT/chrome/userChrome.css"
THEME="$(cat "$STATE_DIR/theme" 2>/dev/null || echo gryffindor-dark)"

# Light vs dark -> Zen's preferred colour scheme.
case "$THEME" in
  *-light) COLOR_SCHEME="light"; ZEN_APPEARANCE="light" ;;
  *)       COLOR_SCHEME="dark";  ZEN_APPEARANCE="dark"  ;;
esac

[ -f "$RENDERED" ] || { echo "zen-theme: rendered userChrome.css missing" >&2; exit 0; }

# Parse profiles.ini -> list of relative profile paths (IsRelative=1).
profile_paths() {
  awk '
    /^\[[Pp]rofile/ { inprof=1; name=""; rel=0; path=""; next }
    inprof && /^Name=/   { name=substr($0,6) }
    inprof && /^IsRelative=1/ { rel=1 }
    inprof && /^Path=/   { path=substr($0,6) }
    inprof && /^\[/ && !/^\[[Pp]rofile/ { if(rel && path) print path; inprof=0 }
    END { if(rel && path) print path }
  ' "$ZEN_ROOT/profiles.ini" 2>/dev/null
}

count=0
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  prof="$ZEN_ROOT/$rel"
  [ -d "$prof" ] || continue

  mkdir -p "$prof/chrome"
  cp -f "$RENDERED" "$prof/chrome/userChrome.css"

  # Write prefs (user.js overrides prefs.js on launch).
  {
    echo "// Hogwarts Rice — generated $(date -u +%FT%TZ)"
    echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
    echo "user_pref(\"layout.css.prefers-color-scheme.content-override\", $([ "$COLOR_SCHEME" = dark ] && echo 0 || echo 1));"
    echo "user_pref(\"browser.theme.content-theme\", $([ "$COLOR_SCHEME" = dark ] && echo 0 || echo 1));"
    echo "user_pref(\"browser.theme.toolbar-theme\", $([ "$COLOR_SCHEME" = dark ] && echo 0 || echo 1));"
    echo "user_pref(\"zen.theme.color-picks.supported\", true);"
    echo "user_pref(\"zen.welcomeScreen.seen\", true);"
  } > "$prof/user.js.hogwarts"

  # Merge into an existing user.js without clobbering user edits.
  if [ -f "$prof/user.js" ]; then
    grep -v 'Hogwarts Rice' "$prof/user.js" | grep -v 'toolkit.legacyUserProfileCustomizations.stylesheets\|layout.css.prefers-color-scheme.content-override\|browser.theme.content-theme\|browser.theme.toolbar-theme\|zen.theme.color-picks.supported\|zen.welcomeScreen.seen' > "$prof/user.js.tmp" || true
    cat "$prof/user.js.hogwarts" >> "$prof/user.js.tmp"
    mv "$prof/user.js.tmp" "$prof/user.js"
    rm -f "$prof/user.js.hogwarts"
  else
    mv "$prof/user.js.hogwarts" "$prof/user.js"
  fi
  count=$((count + 1))
done < <(profile_paths)

echo "zen-theme: themed $count profile(s) for '$THEME' ($COLOR_SCHEME)" >&2
# Zen reads userChrome.css + user.js on (re)start; a running instance needs a
# restart to fully pick up the new palette.
