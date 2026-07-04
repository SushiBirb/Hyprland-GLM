# ⚡ Hogwarts Rice — a Hyprland desktop

> A whimsical, magical "Harry Potter"–inspired Hyprland desktop environment: eight
> live-switchable house themes (Gryffindor, Slytherin, Ravenclaw, Hufflepuff ×
> dark/light), parchment typography, glass panels, and a custom Rofi settings
> menu — all driven by a single palette file.

> **Disclaimer:** This repository and its configurations were generated
> autonomously by an AI agent as part of an experimental test.

---

## ✨ What this is

A complete, opinionated Wayland rice for Arch / CachyOS built around **Hyprland**.
The aesthetic targets the *atmospheric* Harry Potter universe (candle-lit
common rooms, star charts, aged parchment, house heraldry) rather than specific
characters. Every surface — terminal, bar, launcher, notifications, even Zen
Browser — re-skins instantly when you switch houses.

The design borrows two ideas from the community:

| Inspiration | What it contributed |
|---|---|
| [`diinki/linux-antiquity`](https://github.com/diinki/linux-antiquity) | A single centralized "themes dictionary" of semantic colour keys; the warm parchment / hairline-ink aesthetic; serif display typography. |
| [`impulse-os/mod-illogical-impulse-dotfiles`](https://github.com/impulse-os/mod-illogical-impulse-dotfiles) | The **template + sed-render** theming pipeline (one source of truth → every app); sourced Hyprland config fragments; Material-3 animation curves; layer-namespace blur; a self-documenting keybinds grammar. |

This rice re-implements those patterns with **rofi + waybar + kitty + dunst**
(the Illogical Impulse repo uses AGS, and linux-antiquity uses Quickshell).

---

## 🏰 The eight palettes

Four houses, each in a **dark** (starlit night) and **light** (aged parchment)
variant. All eight are defined in **one file** —
[`config/hogwarts/palettes.conf`](config/hogwarts/palettes.conf) — using shared
semantic keys (`ACCENT`, `BG`, `SURFACE`, `TEXT`, `BORDER`, `GLASS`, …).

| House | Dark | Light |
|---|---|---|
| 🦁 Gryffindor | scarlet & gold over warm black | crimson & antique gold on cream |
| 🐍 Slytherin | emerald & silver-green | sage & silver on pale parchment |
| 🦅 Ravenclaw | midnight blue & bronze (book canon) | blue & bronze on cool paper |
| 🦡 Hufflepuff | amber & earth | warm gold on honeyed parchment |

Switching a theme re-renders **kitty, waybar, rofi, dunst, Hyprland colours,
the wallpaper, and Zen Browser chrome**, then live-reloads each component. No
restart required.

---

## 🎨 How the theme engine works

```
palettes.conf  ──►  render.py  ──►  templates/*  ──►  real ~/.config files
  (8 themes)        ({{KEY}} +        (kitty.conf,
                     {{KEY@α}}         style.css,
                     {{KEY#α}})        theme.rasi, …)
                                              │
                              apply-theme.sh  │ reloads each app
                                              ▼
                        kitty · waybar · rofi · dunst · hyprland · zen · swww
```

* `render.py` substitutes placeholders. Two alpha syntaxes are supported because
  apps disagree on colour formats:
  * `{{ACCENT@0.2}}` → `rgba(R, G, B, 0.2)`  *(rofi / waybar / dunst — decimal)*
  * `{{ACCENT#cc}}`  → `rrggbbaa`            *(Hyprland — hex8)*
* `apply-theme.sh` renders every template, deploys it, and reloads the running
  apps. It also picks the right **animation preset** (`snappy` vs `whimsy`)
  and starts the **wallpaper transition**.
* State lives in `~/.local/state/hogwarts/{theme,mode}`.

---

## ⌨ Keybindings

Implemented exactly as specified (see
[`config/hypr/keybinds.conf`](config/hypr/keybinds.conf)):

| Keys | Action |
|---|---|
| **SUPER + T** | Terminal (Kitty) |
| **SUPER + Q** | Close active window |
| **SUPER + 1‑9** | Switch to workspace |
| **SUPER + ALT + 1‑9** | Silently move window to workspace |
| **SUPER + SHIFT + 1‑9** | Move window to workspace **and** follow |
| **SUPER** (release) | App launcher (Rofi) |
| **SUPER + E** | File manager (Dolphin) |
| **SUPER + /** | Show **all** keybindings |
| **SUPER + SHIFT + S** | Hogwarts settings menu |
| **SUPER + SHIFT + X** | Screenshot a region |
| **SUPER + V** | Clipboard history |
| **SUPER + ALT + E** | Emoji picker |
| **CTRL + ALT + DEL** | Power / session menu |

Press **SUPER + /** for the full, always-up-to-date list (it parses the config
file itself, so it can never drift).

---

## 🧙 The Rofi "Settings Menu"

`SUPER + SHIFT + S` opens a Rofi menu that lets you:

* **Switch the 8 house themes** — live, with wallpaper transition.
* **Toggle "Whimsy" animations** — minimal/snappy ⇄ heavy bouncy "enchanted"
  motion (springy beziers, pop-in windows, sliding workspaces).
* **Toggle window blur** on/off at runtime.
* **View all keybindings**.
* **Add a custom keybinding** (guided prompts → written to
  `custom-keybinds.conf`, never overwritten by updates).

---

## 📦 Software stack

| Role | App | Notes |
|---|---|---|
| Compositor | **Hyprland** | classic `hyprland.conf` (canonical) + a `hyprland.lua` for very recent builds |
| Terminal | **Kitty** | transparent background; **cursor-line tracing explicitly disabled** (`cursor_trail 0`) |
| App launcher / menus | **Rofi** | drun launcher + dmenu-driven settings/power/keybind/emoji/clipboard menus |
| Bar | **Waybar** | Cinzel clock, Roman-numeral workspaces, house badge that opens the settings menu |
| Notifications | **Dunst** | themed, rounded, frame-tinted by the active accent |
| File manager | **Dolphin** | |
| Browser | **Zen Browser** | dynamically themed via a generated `userChrome.css` per profile |
| Screenshots | **grim + slurp + swappy** | |
| Colour picker | **hyprpicker** | |
| Wallpaper | **swww** (or the maintained `awww` fork) | 4K procedurally-rendered house wallpapers |

### Fonts (bundled)
* **Cinzel** & **Cinzel Decorative** — the Roman-inscription display face (titles, clock, sigils).
* **EB Garamond** & **Cormorant Garamond** — body serif (rofi items, waybar).
* **MedievalSharp**, **Pirata One**, **UnifrakturCook** — accents / blackletter.
* **JetBrainsMono Nerd Font** — terminal.
* **Material Symbols** — UI icons.

---

## 🚀 Installation

```bash
git clone git@github.com:SushiBirb/Hyprland-GLM.git
cd Hyprland-GLM
./install.sh
```

The installer:

1. Installs all dependencies via `pacman` (+ `paru`/`yay` for `swww`).
2. Installs the bundled magical fonts.
3. Renders (or copies) the 4K wallpapers.
4. **Backs up** any existing configs to `~/hogwarts-backups/<timestamp>/`.
5. Deploys configs and the theme engine to `~/.config`.
6. Applies the default theme (Gryffindor dark / snappy).

Flags: `--no-install` (skip package install), `--gen-wallpapers` (re-render),
`--use-lua` (use the modern `hyprland.lua` instead of `hyprland.conf`).

> Requires an Arch / CachyOS system with an AUR helper (`paru` or `yay`) for
> `swww`. On builds where `swww` resolves to the `awww` fork, the scripts
> detect and use it automatically.

Log out and back in (or restart Hyprland) to see everything come together.

---

## 🗂 Repository layout

```
hogwarts-rice/
├── config/                       # → deployed to ~/.config
│   ├── hypr/                     #   hyprland.conf (canonical) + hyprland.lua
│   │   ├── env.conf  execs.conf  general.conf  rules.conf  keybinds.conf
│   │   ├── colors.conf  (generated)   active-animations.conf (generated)
│   │   ├── animations-snappy.conf   animations-whimsy.conf
│   │   └── custom/  custom-keybinds.conf   (user overrides)
│   ├── kitty/ waybar/ rofi/ dunst/ zen/
│   └── hogwarts/                # the theme engine
│       ├── palettes.conf        #   THE single source of truth (8 themes)
│       ├── scripts/             #   render.py, apply-theme.sh, set-theme.sh, zen-theme.sh
│       └── templates/           #   kitty/ waybar/ rofi/ dunst/ hypr/ zen/
├── assets/
│   ├── fonts/                   # bundled Cinzel / Garamond / … TTFs
│   ├── wallpapers/              # 4K PNGs (generated)
│   └── icons/                   # notification glyphs
├── scripts/generate-wallpapers.sh
├── install.sh
└── README.md
```

---

## 🎭 Design notes

* **Glass, not flat.** Panels (waybar, rofi, dunst) render at ~50–90% opacity and
  rely on per-layer Hyprland blur (`layerrule = blur, <namespace>`) for the
  stained-glass look popularized by linux-antiquity.
* **Inked outlines.** Hairline 1–2px borders in a near-black `BORDER` colour give
  the "engraved" feel; never pure neutral — every dark base carries a faint house
  hue tint.
* **Roman numerals.** Workspaces render as Ⅰ–Ⅹ in the bar, echoing the antique
  star-chart motif.
* **Procedural wallpapers.** Dark variants are a starlit night with a
  house-coloured nebula glow and a faint Cinzel house sigil; light variants are
  aged parchment with a warm vignette. All 4K, generated by
  `scripts/generate-wallpapers.sh` (ImageMagick + a tiny Python starfield).

---

## 📜 License & credit

Generated autonomously as an experiment. Fonts retain their respective licenses
(SIL OFL for Cinzel/Garamond families). House names and the Harry Potter
universe are trademarks of their rights holders; this project is an unofficial,
non-commercial fan homage and is not affiliated with or endorsed by them.

> **Disclaimer:** This repository and its configurations were generated
> autonomously by an AI agent as part of an experimental test.
