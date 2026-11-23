#!/usr/bin/env python3
"""RR Aliados clock fixed to the physical center of the top edge."""
import os
from datetime import datetime

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, GLib

PANEL_H = 36
BG = '#2d0f25'
LINE = '#7e2a61'
GOLD = '#ded116'
PINK = '#ef3c9b'

CSS = f"""
window {{ background-color: transparent; }}
.clock {{
  background-color: transparent;
  border: none;
  padding: 0px;
  margin: 0px;
}}
.date {{ color: {PINK}; font-family: "Inter Tight"; font-size: 7pt; font-weight: bold; }}
.time {{ color: {GOLD}; font-family: "Inter Tight"; font-size: 13pt; font-weight: bold; }}
"""


class RRClock(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_title('Reloj RR')
        self.set_wmclass('rr-clock', 'RR-Clock')
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_accept_focus(False)
        screen = Gdk.Screen.get_default()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        self.set_app_paintable(True)
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
        )
        frame = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        frame.get_style_context().add_class('clock')
        self.date = Gtk.Label(xalign=0.5)
        self.date.get_style_context().add_class('date')
        self.time = Gtk.Label(xalign=0.5)
        self.time.get_style_context().add_class('time')
        frame.add(self.date)
        frame.add(self.time)
        self.add(frame)
        self.set_tooltip_text('Hora del sistema · RR Aliados')
        self.show_all()
        self.update()
        self.reposition()
        GLib.timeout_add_seconds(1, self.update)
        GLib.timeout_add_seconds(5, self.reposition)

    def update(self):
        now = datetime.now()
        self.date.set_text(now.strftime('%Y-%m-%d'))
        self.time.set_text(now.strftime('%H:%M'))
        return True

    def reposition(self):
        screen = Gdk.Screen.get_default()
        # Keep the clock inside the 36 px top panel while giving it more visual weight.
        width = 180
        self.resize(width, PANEL_H)
        self.move((screen.get_width() - width) // 2, 0)
        window = self.get_window()
        if window:
            window.raise_()
        return True


Gtk.init([])
RRClock()
Gtk.main()
