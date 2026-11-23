#!/usr/bin/env python3
# Maximiza toda ventana normal nueva (no diálogos, no barra, no panel RR).
import gi; gi.require_version('Wnck','3.0'); gi.require_version('Gtk','3.0')
from gi.repository import Wnck, Gtk, GLib
EXCLUIR = ('plank','xfce4-panel','apps rr','xfdesktop','escritorio','onboard')
def nueva(scr, w):
    try:
        if w.get_window_type() != Wnck.WindowType.NORMAL: return
        n = (w.get_name() or '').lower(); c = (w.get_class_group_name() or '').lower()
        if any(x in n or x in c for x in EXCLUIR): return
        if w.get_transient() is not None: return
        GLib.timeout_add(400, lambda: (w.maximize() if not w.is_maximized() else None) and False)
    except Exception: pass
scr = Wnck.Screen.get_default(); scr.force_update()
scr.connect('window-opened', nueva)
Gtk.main()
