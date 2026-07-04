#!/usr/bin/env bash
# ============================================================================
#  generate-wallpapers.sh — procedurally renders the 8 Hogwarts wallpapers
#  at 3840x2160 (4K) using ImageMagick 7 + a tiny Python starfield.
#  Uses only fast operations (radial-gradient / label / per-pixel stars);
#  no large-radius blurs.
#  Output: assets/wallpapers/*.png
# ============================================================================
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/assets/wallpapers}"
mkdir -p "$OUT"
W=3840; H=2160
MAGICK="${MAGICK:-magick}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

gen_stars() { # outfile  seed  count
  python3 - "$1" "$2" "$3" "$W" "$H" <<'PY'
import random, sys, struct, zlib
out, seed, n = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
W, H = int(sys.argv[4]), int(sys.argv[5])
random.seed(seed)
raw = bytearray(W * H * 4)
for _ in range(n):
    x = random.randint(0, W-1); y = random.randint(0, H-1)
    r = random.choice([0, 0, 0, 1, 1, 2])
    b = random.uniform(0.55, 1.0)
    R = r + 1
    for dy in range(-R, R+1):
        for dx in range(-R, R+1):
            xx, yy = x+dx, y+dy
            if 0 <= xx < W and 0 <= yy < H:
                d = (dx*dx + dy*dy) ** 0.5
                if d <= R:
                    a = int(b * 255 * max(0, 1 - d/(R+0.5)))
                    i = (yy*W + xx) * 4
                    raw[i]=255; raw[i+1]=255; raw[i+2]=255
                    if a > raw[i+3]: raw[i+3] = a
def chunk(t, d):
    c = t + d
    return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
sig = b'\x89PNG\r\n\x1a\n'
ihdr = struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0)
rows = b''.join(b'\x00' + bytes(raw[y*W*4:(y+1)*W*4]) for y in range(H))
idat = zlib.compress(rows, 6)
with open(out, 'wb') as f:
    f.write(sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b''))
PY
}

# render_dark  <file>  <bg>  <glow>  <sigil>  <seed>
render_dark() {
  local file="$1" bg="$2" glow="$3" sigil="$4" seed="$5"
  # base
  $MAGICK -size ${W}x${H} xc:"$bg" "$TMP/base.png"
  # soft house-coloured glow (lower-right), via radial gradient
  $MAGICK -size ${W}x${H} radial-gradient:"$glow"-none "$TMP/glow.png"
  # starfield
  gen_stars "$TMP/stars.png" "$seed" 560
  # faint Cinzel house sigil
  $MAGICK -background none -fill white -font Cinzel -pointsize 1500 \
    -gravity center "label:$sigil" -evaluate multiply 0.10 "$TMP/sigil.png"
  # vignette
  $MAGICK -size ${W}x${H} radial-gradient:none-"$bg" -evaluate multiply 0.55 "$TMP/vig.png"
  # composite
  $MAGICK "$TMP/base.png" "$TMP/glow.png" -compose screen -composite \
    "$TMP/stars.png" -compose screen -composite \
    "$TMP/sigil.png" -compose screen -composite \
    "$TMP/vig.png" -compose multiply -composite \
    "$OUT/$file"
  echo "  ✓ $file"
}

# render_light <file>  <paper>  <edge>  <ink>  <sigil>
render_light() {
  local file="$1" paper="$2" edge="$3" ink="$4" sigil="$5"
  $MAGICK -size ${W}x${H} radial-gradient:"$paper"-"$edge" \
    -modulate 104,80,100 "$TMP/base.png"
  # faint ink sigil watermark
  $MAGICK -background none -fill "$ink" -font Cinzel -pointsize 1500 \
    -gravity center "label:$sigil" -evaluate multiply 0.14 "$TMP/sigil.png"
  # warm edge vignette
  $MAGICK -size ${W}x${H} radial-gradient:none-"#7a5a2e" -evaluate multiply 0.28 "$TMP/vig.png"
  $MAGICK "$TMP/base.png" "$TMP/sigil.png" -compose multiply -composite \
    "$TMP/vig.png" -compose multiply -composite \
    "$OUT/$file"
  echo "  ✓ $file"
}

echo "Rendering dark (starry) variants…"
render_dark gryffindor.png     "#140b0d" "#9e2233" "G" 101
render_dark slytherin.png      "#07120e" "#2e8b6f" "S" 202
render_dark ravenclaw.png      "#0a0f1c" "#3d6cb3" "R" 303
render_dark hufflepuff.png     "#15120a" "#c79a16" "H" 404

echo "Rendering light (parchment) variants…"
render_light gryffindor-light.png  "#f3e7cf" "#cdbb96" "#8e1c2b" "G"
render_light slytherin-light.png   "#e6ece4" "#a4b8a9" "#1f6f54" "S"
render_light ravenclaw-light.png   "#e7eaf0" "#a3afc4" "#2b4f8a" "R"
render_light hufflepuff-light.png  "#f3edd6" "#cdbb96" "#a97811" "H"

echo "Done. Wallpapers in: $OUT"
