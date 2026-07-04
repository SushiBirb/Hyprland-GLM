#!/usr/bin/env python3
"""
Hogwarts Rice — palette renderer.

Reads a named theme section from palettes.conf and substitutes {{KEY}} /
{{KEY@alpha}} placeholders into every template file, emitting final configs.

Placeholder syntax (case-sensitive, KEY is uppercase A-Z 0-9 _):
    {{ACCENT}}        -> #RRGGBB
    {{ACCENT@0.2}}    -> rgba(R, G, B, 0.2)   (CSS / rasi / waybar; decimal alpha)
    {{ACCENT@cc}}     -> rgba(R, G, B, 0.80)  (decimal; 2-digit hex alpha)
    {{ACCENT#cc}}     -> rrggbbaa             (Hyprland: use as rgba({{ACCENT#cc}}))

Usage:
    render.py <palettes.conf> <theme_name> <template_dir> <out_dir>
"""
import os
import re
import sys

SECTION_RE = re.compile(r"^\s*\[(.+?)\]\s*$")
LINE_RE = re.compile(r"^\s*([A-Za-z0-9_]+)\s*=\s*(#?[0-9A-Fa-f]+|[\w./-]+)\s*$")
PLACEHOLDER_RE = re.compile(r"\{\{\s*([A-Z0-9_]+)(?:([@#])([0-9a-fA-F.]+))?\s*\}\}")


def hex_to_rgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def alpha_to_decimal(a):
    if "." in a:
        return float(a)
    # 1-2 hex digits
    val = int(a, 16)
    if len(a) <= 2:
        return round(val / 255.0, 3)
    return round(val / 16777215.0, 3)


def hex8(value, alpha):
    """value #RRGGBB + 2-digit-hex alpha -> rrggbbaa (Hyprland format)."""
    h = value.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    a = alpha
    if "." in a:
        a = "%02x" % max(0, min(255, round(float(a) * 255)))
    elif len(a) <= 2:
        a = a.zfill(2)
    else:
        a = a[:2]
    return f"{h}{a}".lower()


def parse_palettes(path, theme):
    colors = {}
    active = None
    with open(path, "r", encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            m = SECTION_RE.match(line)
            if m:
                active = m.group(1).strip().lower()
                continue
            if active != theme.lower():
                continue
            if line.strip().startswith("#") or not line.strip():
                continue
            lm = LINE_RE.match(line)
            if lm:
                colors[lm.group(1).upper()] = lm.group(2).strip()
    if not colors:
        sys.stderr.write(f"render.py: theme '{theme}' not found in {path}\n")
        sys.exit(1)
    return colors


def expand(value, sep, alpha):
    """value is a #RRGGBB string (or passthrough token like a filename)."""
    if value.startswith("#"):
        if sep == "#":
            return hex8(value, alpha)
        if sep == "@":
            r, g, b = hex_to_rgb(value)
            return f"rgba({r}, {g}, {b}, {alpha_to_decimal(alpha)})"
        return value
    # Non-colour token (e.g. WALLPAPER filename): ignore alpha, return raw.
    return value


def render_text(text, colors):
    def repl(m):
        key = m.group(1)
        sep = m.group(2)
        alpha = m.group(3)
        if key not in colors:
            # Leave unknown placeholders untouched so missing keys are visible.
            return m.group(0)
        return expand(colors[key], sep, alpha)
    return PLACEHOLDER_RE.sub(repl, text)


def main():
    if len(sys.argv) != 5:
        sys.stderr.write(__doc__)
        sys.exit(2)
    palettes, theme, tdir, odir = sys.argv[1:5]
    colors = parse_palettes(palettes, theme)
    os.makedirs(odir, exist_ok=True)

    count = 0
    for root, _dirs, files in os.walk(tdir):
        for fn in files:
            src = os.path.join(root, fn)
            rel = os.path.relpath(src, tdir)
            dst = os.path.join(odir, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(src, "r", encoding="utf-8") as fh:
                content = fh.read()
            out = render_text(content, colors)
            with open(dst, "w", encoding="utf-8") as fh:
                fh.write(out)
            count += 1
    print(f"render.py: rendered {count} files for theme '{theme}' -> {odir}")


if __name__ == "__main__":
    main()
