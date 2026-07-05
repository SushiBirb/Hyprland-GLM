#!/usr/bin/env python3
"""
Hogwarts Rice — settings panel (illogical-impulse-style sidebar).

A GTK3 + gtk-layer-shell panel anchored to the right edge.  It faithfully
re-implements the illogical-impulse "sideright" settings menu, adapted to the
Hogwarts theme engine:

  • quick toggles row (night light, idle inhibitor, invert, bluetooth, wifi)
  • tabbed center area with an "Appearance" tab holding:
        - Hogwarts theme grid (8 houses)        <- full live theme switching
        - Light/Dark segmented control
        - Animation preset (Snappy / Whimsy) segmented control
        - Blur, X-ray, Animations switches
        - Blur Size & Passes spin buttons
        - Transparency switch
  • a calendar

Run with no args to toggle (a second invocation closes the running instance).
Bound to SUPER+SHIFT+S and the Waybar house badge.
"""
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, GtkLayerShell, GLib, Gdk, Gio

import os
import re
import shlex
import signal
import subprocess
import sys
import time

CONFIG = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
STATE = os.path.join(os.path.expanduser(os.environ.get("XDG_STATE_HOME", "~/.local/state")), "hogwarts")
HW = os.path.join(CONFIG, "hogwarts")
PALETTES = os.path.join(HW, "palettes.conf")
SETTHEME = os.path.join(HW, "scripts", "set-theme.sh")
APPLYTHEME = os.path.join(HW, "scripts", "apply-theme.sh")
PIDFILE = os.path.join(STATE, "settings-panel.pid")
WIDTH = 400

os.makedirs(STATE, exist_ok=True)


# ---------------------------------------------------------------- helpers -----
def sh(cmd):
    """Run a shell command, return stdout string (empty on failure)."""
    try:
        return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=8).stdout.strip()
    except Exception:
        return ""


def run(cmd):
    try:
        subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


def hypr(opt):
    """Read a Hyprland integer option via hyprctl -j getoption."""
    out = sh(f"hyprctl getoption -j {opt} 2>/dev/null")
    if not out:
        return None
    try:
        import json
        d = json.loads(out)
        return d.get("int", d.get("float"))
    except Exception:
        return None


def hypr_set(opt, val):
    run(f"hyprctl keyword {opt} {val}")


def hypr_str(opt):
    """Read a Hyprland string option (e.g. screen_shader)."""
    out = sh(f"hyprctl getoption -j {opt} 2>/dev/null")
    if not out:
        return ""
    try:
        import json
        d = json.loads(out)
        v = d.get("str", "")
        return v if isinstance(v, str) else ""
    except Exception:
        return ""


def read_state(name, default=""):
    try:
        with open(os.path.join(STATE, name)) as f:
            return f.read().strip() or default
    except Exception:
        return default


def write_state(name, val):
    with open(os.path.join(STATE, name), "w") as f:
        f.write(str(val))


# -------------------------------------------------------------- palette/CSS ----
def parse_palette(theme):
    """Return {KEY: value} for the named theme section from palettes.conf."""
    colors = {}
    cur = None
    try:
        with open(PALETTES) as f:
            for line in f:
                m = re.match(r"\s*\[(.+?)\]\s*$", line)
                if m:
                    cur = m.group(1).strip().lower()
                    continue
                if cur != theme.lower():
                    continue
                lm = re.match(r"\s*([A-Za-z0-9_]+)\s*=\s*(\S+)\s*$", line)
                if lm:
                    colors[lm.group(1).upper()] = lm.group(2).strip()
    except Exception:
        pass
    return colors


def hx(c, a=None):
    """#RRGGBB -> 'rgba(r,g,b,a)' (a default 1.0)."""
    c = c.lstrip("#")
    if len(c) == 3:
        c = "".join(ch * 2 for ch in c)
    r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    return f"rgba({r},{g},{b},{a if a is not None else 1.0})"


def build_css(colors):
    C = lambda k, d="#222222": colors.get(k, d)
    return f"""
    @define-color bg        {hx(C('BG'))};
    @define-color surface   {hx(C('SURFACE'))};
    @define-color surfalt   {hx(C('SURFACE_ALT'))};
    @define-color text      {hx(C('TEXT'))};
    @define-color textdim   {hx(C('TEXT_DIM'))};
    @define-color accent    {hx(C('ACCENT'))};
    @define-color accent2   {hx(C('ACCENT2'))};
    @define-color border    {hx(C('BORDER'))};
    @define-color urgent    {hx(C('Urgent', C('URGENT')))};

    * {{ transition: all 200ms ease; }}
    #panel {{
        background: {hx(C('BG'), 0.96)};
        border-left: 1px solid @border;
    }}
    .scrolledwindow {{ background: transparent; }}
    label {{ color: @text; font-family: 'EB Garamond', sans-serif; }}
    .title {{ font-family: 'Cinzel', serif; font-weight: 700; }}
    .section-head {{
        color: @accent2; font-family: 'Cinzel', serif; font-weight: 600;
        font-size: 13px; padding: 10px 6px 4px 6px;
    }}
    .group {{
        background: {hx(C('SURFACE'), 0.7)};
        border-radius: 14px; padding: 8px; margin: 4px 8px;
        border: 1px solid {hx(C('BORDER'), 0.6)};
    }}
    .row {{ border-radius: 10px; padding: 6px 10px; }}
    .row:hover {{ background: {hx(C('SURFACE_ALT'), 0.9)}; }}
    .dim {{ color: @textdim; }}
    .icon {{ font-family: 'Material Symbols Outlined'; font-size: 18px; }}
    .pill {{
        background: {hx(C('SURFACE_ALT'), 0.5)}; color: @textdim;
        border-radius: 18px; padding: 8px 10px; border: 1px solid @border;
    }}
    .pill:hover {{ background: {hx(C('SURFACE_ALT'), 0.8)}; color: @text; }}
    .pill:checked {{ background: @accent; color: {hx(C('BG'))}; border-color: @accent; }}

    /* theme grid */
    .theme-cell {{
        border-radius: 12px; padding: 10px 6px; border: 1px solid @border;
        background: {hx(C('SURFACE'), 0.9)};
    }}
    .theme-cell:hover {{ background: {hx(C('SURFACE_ALT'))}; }}
    .theme-cell.selected {{ border: 2px solid @accent; }}
    .swatch {{ border-radius: 9999px; min-width: 26px; min-height: 26px; }}
    .theme-name {{ font-family: 'Cinzel'; font-size: 11px; }}

    /* segmented control */
    .seg {{ background: {hx(C('SURFACE_ALT'), 0.6)}; border-radius: 12px;
           border: 1px solid @border; }}
    .seg button {{ border-radius: 10px; padding: 6px 14px; }}
    .seg button:checked {{ background: @accent; color: {hx(C('BG'))}; }}

    switch slider {{ background: @textdim; }}
    switch:checked {{ background: @accent; }}
    spinbutton {{ background: @surface; border-radius: 8px; border: 1px solid @border; }}
    calendar {{ color: @text; }}
    calendar:selected {{ background: @accent; color: {hx(C('BG'))}; border-radius: 8px; }}
    calendar.header {{ color: @accent2; font-family: 'Cinzel'; }}
    separator {{ background: {hx(C('BORDER'), 0.5)}; }}
    .foot {{ color: @textdim; font-style: italic; font-size: 11px; padding: 4px; }}
    """


# -------------------------------------------------------------- widget bits ----
class Panel(Gtk.Window):
    def __init__(self):
        super().__init__(title="Hogwarts Settings")
        self.set_default_size(WIDTH, -1)
        self.get_style_context().add_class("panel")
        self.set_name("panel")
        self.connect("destroy", self.on_destroy)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "hogwarts-settings")
        for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM, GtkLayerShell.Edge.RIGHT):
            GtkLayerShell.set_anchor(self, edge, True)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        # ON_DEMAND lets Escape/close keys work; it is safe because the panel
        # releases the keyboard the moment it is closed.
        try:
            GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)
        except Exception:
            pass
        self.connect("key-press-event", self.on_key)

        self.theme = read_state("theme", "gryffindor-dark")
        self.mode = read_state("mode", "snappy")
        self.build()
        self.apply_css()

    def on_destroy(self, *_):
        try:
            os.path.exists(PIDFILE) and os.remove(PIDFILE)
        except Exception:
            pass
        Gtk.main_quit()

    # -- layout -----------------------------------------------------------
    def build(self):
        # The panel is just its content; the layer is anchored to the right
        # edge.  Closing is done via Escape (ON_DEMAND keyboard) or by toggling
        # the keybind (a second launch SIGTERMs the running instance).
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        box.get_style_context().add_class("panel")
        box.set_margin_top(14)
        box.set_margin_bottom(14)
        box.set_size_request(WIDTH, -1)
        box.set_margin_start(8)
        box.set_margin_end(8)

        box.pack_start(self.header(), False, False, 0)
        box.pack_start(self.quick_toggles(), False, False, 0)
        box.pack_start(self.tabs(), True, True, 0)
        box.pack_start(self.calendar_widget(), False, False, 0)
        self.add(box)
        self.add(box)

    def header(self):
        h = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        h.set_margin_start(16)
        h.set_margin_end(16)
        crest = Gtk.Label(label="\u2696")  # ⚖ emblem-ish
        crest.get_style_context().add_class("icon")
        crest.get_style_context().add_class("title")
        crest.set_markup("<span font='Cinzel 22' weight='bold'>\u2696</span>")
        title = Gtk.Label(label="Hogwarts")
        title.get_style_context().add_class("title")
        title.set_markup("<span font='Cinzel 22' weight='bold'>Hogwarts</span>")
        h.pack_start(crest, False, False, 0)
        h.pack_start(title, False, False, 0)
        # uptime
        self.uptime = Gtk.Label(label="")
        self.uptime.get_style_context().add_class("dim")
        self.uptime.set_markup("<span font_size='small'></span>")
        self.refresh_uptime()
        GLib.timeout_add_seconds(30, self.refresh_uptime)
        h.pack_start(self.uptime, False, False, 0)
        # spacer + buttons
        h.pack_start(Gtk.Label(), True, True, 0)
        for icon, tip, fn in (("\ue5d5", "Reload Hyprland", lambda: run("hyprctl reload")),
                             ("\ue8ac", "Session menu", self.open_power)):
            b = Gtk.Button(label=icon)
            b.get_style_context().add_class("icon")
            b.set_tooltip_text(tip)
            b.set_relief(Gtk.ReliefStyle.NONE)
            b.connect("clicked", lambda w, f=fn: f())
            h.pack_start(b, False, False, 0)
        return h

    def refresh_uptime(self):
        out = sh("uptime -p 2>/dev/null || cat /proc/uptime")
        m = re.search(r"up\s+(.+?),\s+\d+", out)
        txt = m.group(1) if m else ""
        self.uptime.set_markup(f"<span font_size='small' font='EB Garamond'>{txt}</span>")
        return True

    # -- quick toggles row ------------------------------------------------
    def quick_toggles(self):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        row.set_margin_start(12)
        row.set_margin_end(12)
        row.set_homogeneous(True)
        for icon, tip, getter, toggle in self.toggles():
            b = self.toggle_button(icon, tip, getter, toggle)
            row.pack_start(b, True, True, 0)
        return row

    def toggles(self):
        return [
            ("\ue1d8", "Wi-Fi", lambda: sh("nmcli radio wifi") == "enabled",
             lambda v: run(f"nmcli radio wifi {'on' if v else 'off'}")),
            ("\ue1a7", "Bluetooth", lambda: sh("rfkill list bluetooth") != "" and "yes" in sh("bluetoothctl show | grep Powered"),
             lambda v: run(f"rfkill {'unblock' if v else 'block'} bluetooth")),
            ("\ue1ac", "Night light", lambda: sh("pidof gammastep") != "",
             self.toggle_nightlight),
            ("\ue1f5", "Invert colors", lambda: hypr_str("decoration:screen_shader").replace("[", "").replace("]", "").strip().upper() not in ("", "EMPTY"),
             self.toggle_invert),
            ("\uefef", "Keep awake", lambda: sh(f"{HW}/scripts/idle-inhibit.sh status") == "on",
             self.toggle_idle),
        ]

    def toggle_button(self, icon, tip, getter, toggle):
        b = Gtk.ToggleButton()
        lab = Gtk.Label(label=icon)
        lab.get_style_context().add_class("icon")
        b.add(lab)
        b.set_tooltip_text(tip)
        b.set_relief(Gtk.ReliefStyle.NONE)
        b.get_style_context().add_class("pill")
        try:
            b.set_active(bool(getter()))
        except Exception:
            b.set_active(False)
        def on_toggle(w):
            try:
                toggle(w.get_active())
            except Exception:
                pass
        b.connect("toggled", on_toggle)
        return b

    def toggle_nightlight(self, on):
        run("pkill gammastep" if not on else "gammastep -O 4000 &")

    def toggle_invert(self, on):
        shp = os.path.join(CONFIG, "hypr", "shaders", "invert.frag")
        if on:
            if os.path.exists(shp):
                run(f"hyprctl keyword decoration:screen_shader '{shp}'")
            else:
                # no shader available — fall back to a no-op so the toggle still works
                run("hyprctl keyword decoration:screen_shader '[[EMPTY]]'")
        else:
            run("hyprctl keyword decoration:screen_shader '[[EMPTY]]'")

    def toggle_idle(self, on):
        run(f"{HW}/scripts/idle-inhibit.sh {'on' if on else 'off'}")

    def open_power(self):
        run(os.path.join(CONFIG, "rofi", "scripts", "power.sh"))
        self.close()

    # -- tabbed area ------------------------------------------------------
    def tabs(self):
        nb = Gtk.Notebook()
        nb.set_show_border(False)
        nb.get_style_context().add_class("group")
        nb.append_page(self.appearance_tab(), self.tab_label("\ue5d2", "Appearance"))
        nb.append_page(self.about_tab(), self.tab_label("\ue88e", "About"))
        return nb

    def tab_label(self, icon, text):
        b = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        i = Gtk.Label(label=icon)
        i.get_style_context().add_class("icon")
        b.pack_start(i, False, False, 0)
        b.pack_start(Gtk.Label(label=text), False, False, 0)
        b.set_margin_start(8)
        b.set_margin_end(8)
        return b

    def appearance_tab(self):
        sw = Gtk.ScrolledWindow()
        sw.set_propagate_natural_height(True)
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        vbox.set_margin_start(10)
        vbox.set_margin_end(10)
        vbox.set_margin_top(10)
        vbox.set_margin_bottom(10)

        vbox.pack_start(self.section("House Theme"), False, False, 0)
        vbox.pack_start(self.theme_grid(), False, False, 0)

        vbox.pack_start(self.section("Variant"), False, False, 0)
        vbox.pack_start(self.lightdark_seg(), False, False, 0)

        vbox.pack_start(self.section("Animation Preset"), False, False, 0)
        vbox.pack_start(self.anim_seg(), False, False, 0)

        vbox.pack_start(self.section("Effects"), False, False, 0)
        vbox.pack_start(self.switch_row("blur_on", "Window blur",
                                        lambda: bool(hypr("decoration:blur:enabled")),
                                        lambda v: hypr_set("decoration:blur:enabled", int(v))), False, False, 0)
        vbox.pack_start(self.switch_row("stack_off", "X-ray blur",
                                        lambda: bool(hypr("decoration:blur:xray")),
                                        lambda v: hypr_set("decoration:blur:xray", int(v))), False, False, 0)
        vbox.pack_start(self.spin_row("target", "Blur size", "decoration:blur:size", 1, 64), False, False, 0)
        vbox.pack_start(self.spin_row("repeat", "Blur passes", "decoration:blur:passes", 1, 10), False, False, 0)
        vbox.pack_start(self.switch_row("animation", "Animations",
                                        lambda: bool(hypr("animations:enabled")),
                                        self.toggle_animations), False, False, 0)
        vbox.pack_start(self.switch_row("border_clear", "Transparency",
                                        lambda: read_state("transparency", "translucent") == "translucent",
                                        self.toggle_transparency), False, False, 0)

        note = Gtk.Label(label="Changes apply live")
        note.get_style_context().add_class("foot")
        note.set_margin_top(6)
        vbox.pack_start(note, False, False, 0)
        sw.add(vbox)
        return sw

    def section(self, text):
        l = Gtk.Label(label=text.upper())
        l.get_style_context().add_class("section-head")
        l.set_halign(Gtk.Align.START)
        return l

    # -- theme grid (the core) -------------------------------------------
    def theme_grid(self):
        all_themes = [t.strip() for t in sh(f"{SETTHEME} --list").splitlines() if t.strip()]
        # one cell per unique house (4), with the current variant's colours.
        houses = []
        seen = set()
        for t in all_themes:
            house = t.rsplit("-", 1)[0]
            if house not in seen:
                seen.add(house)
                houses.append(house)
        current = read_state("theme", "gryffindor-dark")
        current_house = current.rsplit("-", 1)[0]
        grid = Gtk.FlowBox()
        grid.set_homogeneous(True)
        grid.set_min_children_per_line(2)
        grid.set_max_children_per_line(2)
        grid.set_selection_mode(Gtk.SelectionMode.NONE)
        grid.set_row_spacing(6)
        grid.set_column_spacing(6)
        self.theme_cells = {}
        for house in houses:
            cell = self.theme_cell(house, current)
            if house == current_house:
                cell.get_style_context().add_class("selected")
            self.theme_cells[house] = cell
            grid.add(cell)
        return grid

    def theme_cell(self, house, current_theme):
        # Use the current variant of this house for the swatch colours.
        variant = current_theme.rsplit("-", 1)[1] if "-" in current_theme else "dark"
        theme = f"{house}-{variant}"
        pal = parse_palette(theme)
        label = house.capitalize()
        cell = Gtk.Button()
        inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        sw = Gtk.Box()
        sw.get_style_context().add_class("swatch")
        sw.set_name(f"sw-{house}")
        acc = pal.get("ACCENT", "#888888")
        acc2 = pal.get("ACCENT2", "#aaaaaa")
        provider_data = f"#sw-{house} {{ background: {hx(acc)}; border: 3px solid {hx(acc2)}; }}"
        nm = Gtk.Label(label=label)
        nm.get_style_context().add_class("theme-name")
        inner.pack_start(sw, False, False, 0)
        inner.pack_start(nm, False, False, 0)
        cell.add(inner)
        cell.get_style_context().add_class("theme-cell")
        cell.connect("clicked", lambda w, h=house: self.pick_house(h))
        self._swatch_css(cell, provider_data, f"s-{house}")
        return cell

    def _swatch_css(self, widget, css, klass):
        if not css:
            return
        try:
            prov = Gtk.CssProvider()
            prov.load_from_data(css.encode())
            widget.get_style_context().add_provider(prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1)
        except Exception:
            pass

    def pick_house(self, house):
        # Keep the current variant when switching house.
        cur = read_state("theme", "gryffindor-dark")
        variant = cur.rsplit("-", 1)[1] if "-" in cur else "dark"
        new = f"{house}-{variant}"
        if new not in sh(f"{SETTHEME} --list"):
            return
        write_state("theme", new)
        run(f"{APPLYTHEME}")
        for h, cell in self.theme_cells.items():
            ctx = cell.get_style_context()
            (ctx.add_class if h == house else ctx.remove_class)("selected")
        self.theme = new
        self.apply_css()
        self.sync_lightdark_seg()

    # -- segmented controls ----------------------------------------------
    def lightdark_seg(self):
        box = Gtk.Box(spacing=6)
        box.get_style_context().add_class("seg")
        box.set_homogeneous(True)
        self.ld_light = Gtk.ToggleButton(label="\u2600  Light")
        self.ld_dark = Gtk.ToggleButton(label="\u263e  Dark")
        for b in (self.ld_light, self.ld_dark):
            b.get_style_context().add_class("seg")
            box.pack_start(b, True, True, 0)
        self.sync_lightdark_seg()
        self.ld_light.connect("clicked", self._pick_variant, "light")
        self.ld_dark.connect("clicked", self._pick_variant, "dark")
        self.ld_box = box
        return box

    def sync_lightdark_seg(self):
        cur = read_state("theme", "gryffindor-dark")
        self.ld_light.set_active(cur.endswith("-light"))
        self.ld_dark.set_active(not cur.endswith("-light"))

    def _pick_variant(self, btn, variant):
        # Enforce radio-like behaviour (clicked fires on user action only).
        btn.set_active(True)
        other = self.ld_dark if btn is self.ld_light else self.ld_light
        other.set_active(False)
        cur = read_state("theme", "gryffindor-dark")
        house = cur.rsplit("-", 1)[0]
        new = f"{house}-{variant}"
        if new in sh(f"{SETTHEME} --list"):
            write_state("theme", new)
            run(f"{APPLYTHEME}")
            self.theme = new
            self.apply_css()
            # keep the current house highlighted
            for h, cell in self.theme_cells.items():
                ctx = cell.get_style_context()
                (ctx.add_class if h == house else ctx.remove_class)("selected")

    def anim_seg(self):
        box = Gtk.Box(spacing=6)
        box.get_style_context().add_class("seg")
        box.set_homogeneous(True)
        self.anim_snappy = Gtk.ToggleButton(label="\u26a1  Snappy")
        self.anim_whimsy = Gtk.ToggleButton(label="\u2728  Whimsy")
        for b in (self.anim_snappy, self.anim_whimsy):
            b.get_style_context().add_class("seg")
            box.pack_start(b, True, True, 0)
        m = read_state("mode", "snappy")
        self.anim_snappy.set_active(m == "snappy")
        self.anim_whimsy.set_active(m == "whimsy")
        self.anim_snappy.connect("clicked", self._pick_mode, "snappy")
        self.anim_whimsy.connect("clicked", self._pick_mode, "whimsy")
        return box

    def _pick_mode(self, btn, mode):
        btn.set_active(True)
        other = self.anim_whimsy if btn is self.anim_snappy else self.anim_snappy
        other.set_active(False)
        write_state("mode", mode)
        run(f"{APPLYTHEME}")
        self.mode = mode
        self.apply_css()

    # -- switch / spin rows ----------------------------------------------
    def switch_row(self, icon, name, getter, setter):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.get_style_context().add_class("row")
        i = Gtk.Label(label=icon)
        i.get_style_context().add_class("icon")
        row.pack_start(i, False, False, 0)
        row.pack_start(Gtk.Label(label=name), False, False, 0)
        row.pack_start(Gtk.Label(), True, True, 0)
        sw = Gtk.Switch()
        try:
            sw.set_active(bool(getter()))
        except Exception:
            sw.set_active(False)
        sw.connect("state-set", lambda w, v: setter(v))
        row.pack_start(sw, False, False, 0)
        return row

    def spin_row(self, icon, name, opt, lo, hi):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.get_style_context().add_class("row")
        i = Gtk.Label(label=icon)
        i.get_style_context().add_class("icon")
        row.pack_start(i, False, False, 0)
        row.pack_start(Gtk.Label(label=name), False, False, 0)
        row.pack_start(Gtk.Label(), True, True, 0)
        sp = Gtk.SpinButton.new_with_range(lo, lo, 1)
        sp.set_range(lo, hi)
        cur = hypr(opt)
        sp.set_value(cur if isinstance(cur, (int, float)) else lo)
        sp.connect("value-changed", lambda w: hypr_set(opt, int(w.get_value())))
        row.pack_start(sp, False, False, 0)
        return row

    def toggle_animations(self, on):
        hypr_set("animations:enabled", int(on))
        run(f"gsettings set org.gnome.desktop.interface enable-animations {'true' if on else 'false'}")

    def toggle_transparency(self, on):
        val = "translucent" if on else "solid"
        write_state("transparency", val)
        # Toggle the kitty window opacity + layer blur for a live "glass" effect.
        if on:
            hypr_set("decoration:blur:enabled", 1)
        run(f"{APPLYTHEME}")

    # -- about + calendar -------------------------------------------------
    def about_tab(self):
        sw = Gtk.ScrolledWindow()
        sw.set_propagate_natural_height(True)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_start(14)
        box.set_margin_end(14)
        box.set_margin_top(14)
        title = Gtk.Label()
        title.set_markup("<span font='Cinzel 20' weight='bold'>\u2696 Hogwarts Rice</span>")
        title.set_halign(Gtk.Align.START)
        box.pack_start(title, False, False, 0)
        host = sh("hostnamectl status --static 2>/dev/null || hostname")
        kernel = sh("uname -r")
        de = "Hyprland " + sh("hyprctl version 2>/dev/null | head -1 | awk '{print $2}'")
        for k, v in (("Host", host), ("Kernel", kernel), ("Session", de),
                     ("Theme", read_state("theme", "gryffindor-dark")),
                     ("Preset", read_state("mode", "snappy"))):
            line = Gtk.Label()
            line.set_markup(f"<span color='#aaa'>{k}</span>   <b>{v}</b>")
            line.set_halign(Gtk.Align.START)
            box.pack_start(line, False, False, 0)
        box.pack_start(self._kspeed(), False, False, 8)
        note = Gtk.Label(label="Generated autonomously as an experiment.")
        note.get_style_context().add_class("foot")
        note.set_line_wrap(True)
        box.pack_start(note, False, False, 0)
        sw.add(box)
        return sw

    def _kspeed(self):
        out = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        lbl = Gtk.Label()
        lbl.set_markup("<span font='Cinzel' weight='bold' color='#aaa'>Quick actions</span>")
        lbl.set_halign(Gtk.Align.START)
        out.pack_start(lbl, False, False, 0)
        for keys, desc in (("SUPER + T", "Terminal"), ("SUPER", "Launcher"),
                           ("SUPER + E", "Files"), ("SUPER + /", "Keybinds"),
                           ("SUPER + SHIFT + S", "This panel")):
            row = Gtk.Label()
            row.set_markup(f"<tt><b>{keys:<18}</b></tt> {desc}")
            row.set_halign(Gtk.Align.START)
            out.pack_start(row, False, False, 0)
        return out

    def calendar_widget(self):
        wrap = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        wrap.set_margin_start(12)
        wrap.set_margin_end(12)
        cal = Gtk.Calendar()
        cal.get_style_context().add_class("group")
        wrap.pack_start(cal, False, False, 0)
        return wrap

    # -- styling + behaviour ---------------------------------------------
    def apply_css(self):
        colors = parse_palette(self.theme)
        css = build_css(colors)
        if hasattr(self, "_cssprov"):
            self.get_style_context().remove_provider(self._cssprov)
        prov = Gtk.CssProvider()
        prov.load_from_data(css.encode())
        self._cssprov = prov
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def on_key(self, _w, ev):
        if ev.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False


# --------------------------------------------------------------- singleton ----
def already_running():
    try:
        with open(PIDFILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, 0)
        return pid
    except Exception:
        return None


def main():
    pid = already_running()
    if pid:
        try:
            os.kill(pid, signal.SIGTERM)
        except Exception:
            pass
        try:
            os.remove(PIDFILE)
        except Exception:
            pass
        return

    signal.signal(signal.SIGTERM, lambda *_: (os.path.exists(PIDFILE) and os.remove(PIDFILE), Gtk.main_quit(), sys.exit(0)))
    win = Panel()
    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))
    win.show_all()
    # Self-terminate in test mode so the panel can never wedge the session.
    if os.environ.get("HOGWARTS_PANEL_TEST"):
        GLib.timeout_add_seconds(3, lambda: (os.remove(PIDFILE) if os.path.exists(PIDFILE) else None, Gtk.main_quit()))
    Gtk.main()


if __name__ == "__main__":
    main()
