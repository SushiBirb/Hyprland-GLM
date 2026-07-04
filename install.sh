#!/usr/bin/env bash
# ============================================================================
#  Hogwarts Rice — automated installer
# ----------------------------------------------------------------------------
#  Replicates the full Hyprland desktop on a fresh Arch / CachyOS system.
#
#  Usage:  ./install.sh           # install everything (interactive prompts off)
#          ./install.sh --no-install   # only deploy configs (deps already met)
#          ./install.sh --gen-wallpapers   # (re)render the 4K wallpapers
#
#  Idempotent: safe to re-run.  Existing user configs are backed up with a
#  timestamp into ~/hogwarts-backups/.
# ============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${0}")" && pwd)"
CONFIG_SRC="$REPO_ROOT/config"
XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE="${XDG_STATE_HOME:-$HOME/.local/state}"

NO_INSTALL=0
GEN_WALL=0
USE_LUA=0
for arg in "$@"; do
  case "$arg" in
    --no-install) NO_INSTALL=1 ;;
    --gen-wallpapers) GEN_WALL=1 ;;
    --use-lua) USE_LUA=1 ;;
    *) echo "unknown flag: $arg" >&2 ;;
  esac
done

c_ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
c_info() { printf '  \033[1;34m•\033[0m %s\n' "$*"; }
c_warn() { printf '  \033[1;33m!\033[0m %s\n' "$*" >&2; }
die()    { printf '  \033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# --- helper: pick the right AUR helper ---------------------------------------
aur_helper() {
  command -v paru >/dev/null && { echo paru; return; }
  command -v yay  >/dev/null && { echo yay;  return; }
  echo ""
}

# --- 0. Preflight ------------------------------------------------------------
[ "$(id -u)" = 0 ] && die "Run as your normal user, not root."
command -v pacman >/dev/null || die "This installer targets Arch / CachyOS (pacman)."
c_info "Hogwarts Rice installer — repo: $REPO_ROOT"

# --- 1. Dependencies ---------------------------------------------------------
PKGS_OFFICIAL=(
  hyprland kitty dolphin rofi waybar dunst grim slurp hyprpicker swappy
  wl-clipboard cliphist jq socat python starship
  ttf-jetbrains-mono-nerd ttf-material-symbols-variable polkit-gnome
  xdg-user-dirs xdg-utils brightnessctl playerctl pavucontrol
  fontconfig
  # wallpaper daemon: prefer swww; fall back to the maintained awww fork.
)
PKGS_AUR=( swww )
PKGS_OPT=( image-roll )   # image-roll is used by swappy (optional editor)

if [ "$NO_INSTALL" -eq 0 ]; then
  c_info "Installing dependencies (this may take a while)…"
  sudo pacman -S --needed --noconfirm "${PKGS_OFFICIAL[@]}" || die "pacman failed"

  HELPER="$(aur_helper)"
  if [ -n "$HELPER" ]; then
    # swww may be provided by the "awww" fork; either satisfies the build.
    $HELPER -S --needed --noconfirm "${PKGS_AUR[@]}" || c_warn "AUR install of ${PKGS_AUR[*]} had issues (awww fork is an acceptable substitute)."
  else
    c_warn "No AUR helper (paru/yay) found.  Install swww manually, or it will fall back to awww."
  fi
  c_ok "Dependencies installed"
fi

# --- 2. Fonts ----------------------------------------------------------------
c_info "Installing bundled magical fonts…"
FONT_DIR="$XDG_DATA/fonts/hogwarts"
mkdir -p "$FONT_DIR"
cp -f "$REPO_ROOT/assets/fonts/"*.ttf "$FONT_DIR/" 2>/dev/null || true
fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
c_ok "Fonts installed"

# --- 3. Wallpapers -----------------------------------------------------------
WALL_DIR="$XDG_DATA/hogwarts/wallpapers"
ICON_DIR="$XDG_DATA/hogwarts/icons"
mkdir -p "$WALL_DIR" "$ICON_DIR"

if [ "$GEN_WALL" -eq 1 ] || [ ! -f "$WALL_DIR/gryffindor.png" ]; then
  if command -v magick >/dev/null 2>&1; then
    c_info "Rendering 4K wallpapers (ImageMagick)…"
    bash "$REPO_ROOT/scripts/generate-wallpapers.sh" "$REPO_ROOT/assets/wallpapers" >/dev/null 2>&1 \
      || c_warn "Wallpaper generation had issues; using pre-rendered copies."
  else
    c_warn "ImageMagick (magick) not found — installing pre-rendered wallpapers as-is."
  fi
fi
cp -f "$REPO_ROOT/assets/wallpapers/"*.png "$WALL_DIR/" 2>/dev/null || true
cp -f "$REPO_ROOT/assets/icons/"*.svg "$ICON_DIR/" 2>/dev/null || true
# keep the repo copy in sync too
mkdir -p "$REPO_ROOT/assets/wallpapers"
c_ok "Wallpapers + icons in place"

# --- 4. Backup existing configs ---------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/hogwarts-backups/$STAMP"
NEEDED_BACKUP=0
for d in hypr kitty waybar rofi dunst hogwarts zen; do
  if [ -e "$XDG_CONFIG/$d" ] && [ ! -L "$XDG_CONFIG/$d" ]; then
    [ "$NEEDED_BACKUP" -eq 0 ] && { mkdir -p "$BACKUP"; c_info "Backing up existing configs to $BACKUP"; }
    cp -r "$XDG_CONFIG/$d" "$BACKUP/" 2>/dev/null || true
    NEEDED_BACKUP=1
  fi
done
[ "$NEEDED_BACKUP" -eq 1 ] && c_ok "Backed up"

# --- 5. Deploy configs -------------------------------------------------------
c_info "Deploying configs to $XDG_CONFIG …"
mkdir -p "$XDG_CONFIG" \
         "$XDG_CONFIG/hypr/custom" \
         "$XDG_CONFIG/zen/chrome" \
         "$XDG_CONFIG/kitty" "$XDG_CONFIG/waybar" "$XDG_CONFIG/dunst"

# The theme engine + every app config tree.
cp -r "$CONFIG_SRC"/* "$XDG_CONFIG/"

# Make scripts executable.
chmod +x "$XDG_CONFIG/hogwarts/scripts/"* "$XDG_CONFIG/rofi/scripts/"* 2>/dev/null || true
chmod +x "$XDG_CONFIG/hogwarts/scripts/render.py" 2>/dev/null || true

# Empty user-override stubs (never overwritten on updates).
for f in "$XDG_CONFIG/hypr/custom/"{env,general,rules}.conf "$XDG_CONFIG/hypr/custom-keybinds.conf"; do
  [ -f "$f" ] || printf '# User overrides — safe to edit.\n' > "$f"
done

# Optional kitty local override (silences the include warning if absent).
[ -f "$XDG_CONFIG/kitty/hogwarts-local.conf" ] || touch "$XDG_CONFIG/kitty/hogwarts-local.conf"

# This repo ships BOTH hyprland.conf (classic, works on every Hyprland version)
# and hyprland.lua (the modern Lua API, used by very recent Hyprland builds).
# By default we keep hyprland.conf as the canonical, active config.  Pass
# --use-lua to keep hyprland.lua active instead (it dofiles colors.lua so it
# stays theme-aware just like the .conf).
if [ "$USE_LUA" -eq 0 ]; then
  if [ -f "$XDG_CONFIG/hypr/hyprland.lua" ]; then
    mv "$XDG_CONFIG/hypr/hyprland.lua" "$XDG_CONFIG/hypr/hyprland.lua.disabled"
    c_info "hyprland.conf is canonical (hyprland.lua disabled). Use --use-lua to switch."
  fi
else
  c_info "Keeping hyprland.lua active (--use-lua)."
fi

c_ok "Configs deployed"

# --- 6. Default state --------------------------------------------------------
mkdir -p "$XDG_STATE/hogwarts"
[ -f "$XDG_STATE/hogwarts/theme" ] || echo "gryffindor-dark" > "$XDG_STATE/hogwarts/theme"
[ -f "$XDG_STATE/hogwarts/mode"  ] || echo "snappy"          > "$XDG_STATE/hogwarts/mode"

mkdir -p "$HOME/Pictures/Screenshots"

# --- 7. Apply the theme (renders every config from the palette) -------------
c_info "Applying default theme (gryffindor-dark / snappy)…"
if "$XDG_CONFIG/hogwarts/scripts/apply-theme.sh" >/dev/null 2>&1; then
  c_ok "Theme applied"
else
  c_warn "apply-theme reported an issue — it will run again on next Hyprland start via exec-once."
fi

# --- 8. Done -----------------------------------------------------------------
cat <<'BANNER'

  ╔══════════════════════════════════════════════════════════════╗
  ║          ⚡  Hogwarts Rice — installation complete  ⚡        ║
  ╠══════════════════════════════════════════════════════════════╣
  ║  Log out and back in (or restart Hyprland) to see it all.    ║
  ║                                                              ║
  ║  SUPER + T          terminal (kitty)                         ║
  ║  SUPER              app launcher (rofi)                      ║
  ║  SUPER + E          file manager (dolphin)                   ║
  ║  SUPER + /          all keybindings                          ║
  ║  SUPER + SHIFT + S  Hogwarts settings menu                   ║
  ║                                                              ║
  ║  Switch the 8 house themes live from the settings menu.      ║
  ╚══════════════════════════════════════════════════════════════╝

BANNER
