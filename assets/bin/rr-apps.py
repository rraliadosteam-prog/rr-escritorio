#!/usr/bin/env python3
# Panel de apps RR: cuadrícula con búsqueda, orden A-Z, recientes y categorías.
import os, sys, signal, gi
gi.require_version('Gtk', '3.0'); gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, Gio, GLib, Pango
PID = os.path.expanduser('~/.cache/rr-apps.pid')
MODO_F = os.path.expanduser('~/.cache/rr-apps.modo')
try:
    old = int(open(PID).read()); os.kill(old, signal.SIGTERM); os.remove(PID); sys.exit(0)
except Exception: pass
os.makedirs(os.path.dirname(PID), exist_ok=True)
open(PID, 'w').write(str(os.getpid()))
OCULTAR = {'app-board.desktop','xfce4-appfinder.desktop','xfce4-run.desktop','rr-apps.desktop',
 'mate-calc.desktop','xfce4-file-manager.desktop','org.gnome.Nautilus.desktop','xfce4-terminal-emulator.desktop',
 'org.gnome.Ptyxis.desktop','engrampa.desktop','org.gnome.TextEditor.desktop','org.gnome.Papers.desktop',
 'org.gnome.Loupe.desktop','org.gnome.Showtime.desktop','xfce4-web-browser.desktop',
 'xfce4-mail-reader.desktop','gucharmap.desktop','onboard-settings.desktop','thunar-bulk-rename.desktop'}
NOMBRES = {'org.gnome.Calculator.desktop':'Calculadora','org.gnome.Calendar.desktop':'Calendario',
 'thunar.desktop':'Archivos','xfce4-terminal.desktop':'Terminal','org.gnome.FileRoller.desktop':'Comprimir archivos',
 'org.xfce.mousepad.desktop':'Editor de texto','atril.desktop':'Visor de PDF','org.xfce.ristretto.desktop':'Visor de imágenes',
 'org.xfce.Parole.desktop':'Reproductor de video','org.gnome.Characters.desktop':'Caracteres y emojis',
 'org.gnome.clocks.desktop':'Relojes','org.gnome.baobab.desktop':'Uso del disco','org.gnome.DiskUtility.desktop':'Discos',
 'simple-scan.desktop':'Escáner','org.gnome.font-viewer.desktop':'Fuentes','org.gnome.Logs.desktop':'Registros',
 'menulibre.desktop':'Editor del menú','org.gnome.seahorse.Application.desktop':'Contraseñas y claves',
 'system-config-printer.desktop':'Impresoras','org.gnome.Rhythmbox3.desktop':'Música','org.gnome.Shotwell.desktop':'Fotos',
 'update-manager.desktop':'Actualizaciones','usb-creator-gtk.desktop':'Crear USB de arranque','org.remmina.Remmina.desktop':'Escritorio remoto',
 'gimp.desktop':'GIMP','advanced':'', 'nm-connection-editor.desktop':'Conexiones de red','org.gnome.DejaDup.desktop':'Copias de seguridad',
 'org.gnome.Snapshot.desktop':'Cámara','org.freedesktop.IBus.Setup.desktop':'Preferencias de IBus','gnome-language-selector.desktop':'Idiomas',
 'gdebi.desktop':'Instalador de paquetes','synaptic.desktop':'Gestor de paquetes Synaptic','org.bluesabre.SgtLauncher.desktop':'Puzles',
 'lightdm-gtk-greeter-settings.desktop':'Pantalla de inicio de sesión','org.xfce.Catfish.desktop':'Buscar archivos'}
def nombre(a): return NOMBRES.get(a.get_id()) or a.get_display_name()
IA = {'chatgpt.desktop','claude.desktop','cursor.desktop','gemini.desktop','perplexity.desktop',
 'deepseek.desktop','grok.desktop','copilot.desktop','ollama.desktop','lm-studio.desktop','jan.desktop','Buzz.desktop'}
IA_PALABRAS = ('chatgpt','claude','gemini','copilot','deepseek','grok','ollama','llm',' ia ',' ai ')
RR = {'rr-apps.desktop'}
CATS = [  # (clave, título, color)
 ('ia','Inteligencia artificial','#be076d'), ('rr','RR ALIADOS','#ded116'), ('internet','Internet y comunicación','#973d8f'),
 ('oficina','Oficina y documentos','#2f8fd8'), ('multimedia','Fotos, música y video','#e8743b'), ('dev','Desarrollo y terminal','#22a884'),
 ('juegos','Juegos','#f2c230'), ('herramientas','Herramientas','#8a8f98'), ('sistema','Sistema','#5b6cff'), ('ajustes','Configuración','#c75fbf')]
COLOR = {k: c for k, _, c in CATS}
def categoria(a):
    i = a.get_id()
    if i in IA or any(w in (' %s ' % nombre(a).lower()) for w in IA_PALABRAS): return 'ia'
    if i in RR: return 'rr'
    c = set((a.get_categories() or '').split(';'))
    if 'Game' in c: return 'juegos'
    if c & {'Settings','DesktopSettings','HardwareSettings'}: return 'ajustes'
    if c & {'Network','WebBrowser','Email','Chat','InstantMessaging','RemoteAccess','FileTransfer'}: return 'internet'
    if c & {'Office','Viewer','WordProcessor','Spreadsheet','Presentation','Dictionary','Scanning'}: return 'oficina'
    if c & {'AudioVideo','Audio','Video','Graphics','Photography','Player','Recorder'}: return 'multimedia'
    if c & {'Development','TerminalEmulator','IDE'}: return 'dev'
    if c & {'System','Monitor','PackageManager','Security'}: return 'sistema'
    return 'herramientas'
def fecha(a):
    try: return os.path.getmtime(a.get_filename())
    except Exception: return 0
apps, vistos = [], set()
for a in Gio.AppInfo.get_all():
    if not a.should_show() or a.get_id() in OCULTAR: continue
    k = nombre(a).lower().strip()
    if k in vistos: continue
    vistos.add(k); apps.append(a)
css = """
window { background-color: rgba(7,0,1,0.94); }
#titulo { font-family: 'Inter Tight'; font-weight: 800; font-size: 30px; color: #fffff3; }
#sub { font-family: 'Lexend'; font-size: 14px; color: #ded116; }
entry { font-family: 'Lexend'; font-size: 18px; padding: 12px 18px; border-radius: 14px;
  background: rgba(255,255,243,0.08); color: #fffff3; border: 2px solid #973d8f; caret-color: #ded116; }
entry:focus { border-color: #be076d; }
flowbox, scrolledwindow, viewport { background: transparent; }
flowboxchild { padding: 0; border-radius: 18px; background: rgba(255,255,243,0.03); }
flowboxchild:hover, flowboxchild:selected, flowboxchild:focus { background: rgba(190,7,109,0.35); }
.app { padding: 14px 8px; }
.app label { font-family: 'Lexend'; font-size: 13px; color: #fffff3; }
.modo { font-family: 'Lexend'; font-size: 14px; font-weight: 600; color: #fffff3; background: rgba(255,255,243,0.08);
  border: none; border-radius: 12px; padding: 8px 18px; box-shadow: none; }
.modo:hover { background: rgba(151,61,143,0.5); }
.modo.activo { background: #ded116; color: #070001; }
#cerrar { font-family: 'Lexend'; font-size: 16px; font-weight: 600; color: #fffff3; background: #be076d; border: none; border-radius: 14px; padding: 10px 22px; box-shadow: none; }
#cerrar:hover { background: #973d8f; }
.seccion { font-family: 'Inter Tight'; font-weight: 800; font-size: 19px; padding: 6px 16px; border-radius: 10px; margin-top: 12px; }
"""
for k, _, c in CATS:
    css += ".s-%s { color: %s; background: alpha(%s, 0.14); border-left: 6px solid %s; }\n" % (k, c, c, c)
    css += ".t-%s { background: alpha(%s, 0.10); } .t-%s:hover { background: alpha(%s, 0.40); }\n" % (k, c, k, c)
p = Gtk.CssProvider(); p.load_from_data(css.encode())
Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
win = Gtk.Window(); win.set_decorated(False); win.fullscreen(); win.set_keep_above(True); win.set_title('Apps RR')
def salir(*a):
    try: os.remove(PID)
    except Exception: pass
    Gtk.main_quit()
win.connect('destroy', salir)
caja = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
for m in ('top','start','end','bottom'): getattr(caja, 'set_margin_' + m)(40 if m != 'start' and m != 'end' else 110)
t = Gtk.Label(label='RR ALIADOS · Apps'); t.set_name('titulo'); t.set_halign(Gtk.Align.START)
s = Gtk.Label(label='%d aplicaciones · escribe para buscar · Esc o clic derecho para cerrar' % len(apps)); s.set_name('sub'); s.set_halign(Gtk.Align.START)
cerrar = Gtk.Button(label='✕  Cerrar'); cerrar.set_name('cerrar'); cerrar.set_valign(Gtk.Align.CENTER); cerrar.connect('clicked', lambda *_: win.destroy())
top = Gtk.Box(spacing=12); tx = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
tx.pack_start(t, False, False, 0); tx.pack_start(s, False, False, 0); top.pack_start(tx, True, True, 0); top.pack_end(cerrar, False, False, 0)
busca = Gtk.SearchEntry(); busca.set_placeholder_text('Buscar una app…')
modos = Gtk.Box(spacing=8); botones = {}
contenido = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
sc = Gtk.ScrolledWindow(); sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC); sc.add(contenido)
flows = []
def abrir(_, child):
    try: child.get_child().app.launch([], None)
    finally: win.destroy()
def filtro(child):
    q = busca.get_text().lower().strip(); a = child.get_child().app
    return not q or q in nombre(a).lower() or q in a.get_display_name().lower() or q in (a.get_description() or '').lower()
def nuevo_flow(lista, cat_color):
    fb = Gtk.FlowBox(); fb.set_valign(Gtk.Align.START); fb.set_max_children_per_line(10); fb.set_min_children_per_line(4)
    fb.set_selection_mode(Gtk.SelectionMode.NONE); fb.set_activate_on_single_click(True); fb.set_row_spacing(10); fb.set_column_spacing(10); fb.set_homogeneous(True)
    for a in lista:
        b = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8); b.get_style_context().add_class('app')
        img = Gtk.Image.new_from_gicon(a.get_icon() or Gio.ThemedIcon.new('application-x-executable'), Gtk.IconSize.DIALOG); img.set_pixel_size(64)
        l = Gtk.Label(label=nombre(a)); l.set_max_width_chars(14); l.set_ellipsize(Pango.EllipsizeMode.END); l.set_justify(Gtk.Justification.CENTER)
        b.pack_start(img, False, False, 0); b.pack_start(l, False, False, 0); b.app = a; b.set_tooltip_text(nombre(a))
        fb.add(b)
        if cat_color: b.get_parent().get_style_context().add_class('t-' + categoria(a))
    fb.set_filter_func(filtro); fb.connect('child-activated', abrir); flows.append(fb)
    return fb
def pintar(modo):
    for w in contenido.get_children(): contenido.remove(w)
    flows.clear()
    for k, bt in botones.items():
        (bt.get_style_context().add_class if k == modo else bt.get_style_context().remove_class)('activo')
    if modo == 'az':
        contenido.pack_start(nuevo_flow(sorted(apps, key=lambda a: nombre(a).lower()), True), False, False, 0)
    elif modo == 'nuevos':
        contenido.pack_start(nuevo_flow(sorted(apps, key=fecha, reverse=True), True), False, False, 0)
    else:
        for k, titulo, _ in CATS:
            lista = sorted([a for a in apps if categoria(a) == k], key=lambda a: nombre(a).lower())
            if not lista: continue
            h = Gtk.Label(label='%s  ·  %d' % (titulo, len(lista))); h.set_halign(Gtk.Align.START)
            h.get_style_context().add_class('seccion'); h.get_style_context().add_class('s-' + k)
            contenido.pack_start(h, False, False, 0); contenido.pack_start(nuevo_flow(lista, True), False, False, 0)
    try: open(MODO_F, 'w').write(modo)
    except Exception: pass
    contenido.show_all(); refiltrar()
def refiltrar(*_):
    for f in flows: f.invalidate_filter()
busca.connect('search-changed', refiltrar)
for k, lab in (('cats','▦  Categorías'), ('az','A–Z  Alfabético'), ('nuevos','✦  Más nuevas')):
    bt = Gtk.Button(label=lab); bt.get_style_context().add_class('modo'); bt.connect('clicked', lambda _w, k=k: pintar(k))
    botones[k] = bt; modos.pack_start(bt, False, False, 0)
def enter(*_):
    for f in flows:
        for c in f.get_children():
            if c.get_child_visible() and c.get_mapped(): abrir(None, c); return
busca.connect('activate', enter)
def tecla(w, e):
    if e.keyval == Gdk.KEY_Escape: win.destroy(); return True
    return False
win.connect('key-press-event', tecla)
win.connect('button-press-event', lambda w, e: (e.button == 3 and (win.destroy() or True)) or False)
GLib.timeout_add(800, lambda: win.connect('focus-out-event', lambda *_: win.destroy()) and False)
for w in (top, busca, modos): caja.pack_start(w, False, False, 0)
caja.pack_start(sc, True, True, 0)
ev = Gtk.EventBox(); ev.add(caja); win.add(ev)
try: inicial = open(MODO_F).read().strip() or 'cats'
except Exception: inicial = 'cats'
win.show_all(); pintar(inicial if inicial in ('cats','az','nuevos') else 'cats'); busca.grab_focus(); Gtk.main()
