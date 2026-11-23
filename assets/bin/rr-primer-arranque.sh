#!/usr/bin/env bash
# RR ALIADOS · se ejecuta UNA vez al entrar a la sesión XFCE nueva.
# Aplica colores, temas, barra superior, menú, Plank y notificaciones; al final se borra de autostart.
set -u
RR="$HOME/.local/share/rr-escritorio"
LOG="$RR/primer-arranque.log"
AUTO="$HOME/.config/autostart/rr-primer-arranque.desktop"
exec >>"$LOG" 2>&1
echo "== $(date) primer arranque RR"
case "${XDG_CURRENT_DESKTOP:-}" in *XFCE*) ;; *) echo "No es XFCE, no hago nada"; exit 0 ;; esac
sleep 4

x() { # canal propiedad tipo valor
  xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4" || echo "aviso: no se pudo $1 $2"
}

# 1) Barra superior: se escribe el XML y se reinicia el panel (xfconfd se relee al reiniciarse).
if [ -f "$RR/xfce4-panel.xml" ]; then
  xfce4-panel --quit 2>/dev/null || true
  sleep 1
  pkill -u "$(id -u)" -x xfconfd 2>/dev/null || true
  sleep 1
  mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
  cp -f "$RR/xfce4-panel.xml" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
  (setsid xfce4-panel >/dev/null 2>&1 &)
  sleep 3
fi

# 2) Apariencia general
x xsettings /Net/ThemeName string RR-Aliados
x xsettings /Net/IconThemeName string RR-Oscuro-Iconos
x xsettings /Gtk/CursorThemeName string Bibata-Modern-Classic
x xsettings /Gtk/CursorThemeSize int 24
x xsettings /Gtk/FontName string "Lexend 10"
x xsettings /Gtk/DecorationLayout string "icon,menu:minimize,maximize,close"
x xsettings /Xfce/SyncThemes bool true

# 3) Ventanas
x xfwm4 /general/theme string RR-Aliados
x xfwm4 /general/button_layout string "O|HMC"
x xfwm4 /general/title_font string "Inter Tight Bold 10"
x xfwm4 /general/title_alignment string center
x xfwm4 /general/full_width_title bool true
x xfwm4 /general/show_app_icon bool false
x xfwm4 /general/borderless_maximize bool true
x xfwm4 /general/placement_mode string center
x xfwm4 /general/use_compositing bool true
x xfwm4 /general/show_frame_shadow bool true
x xfwm4 /general/shadow_opacity int 45
x xfwm4 /general/shadow_delta_y int -4
x xfwm4 /general/shadow_delta_height int 6

# 4) Notificaciones
x xfce4-notifyd /theme string RR-Notify
x xfce4-notifyd /notify-location string bottom-right
x xfce4-notifyd /initial-opacity double 0.95
x xfce4-notifyd /do-slideout bool true

# 5) Plank (barra de abajo que se esconde)
if command -v dconf >/dev/null; then
  P=/net/launchpad/plank/docks/dock1
  dconf write $P/dock-items "['rr-apps.dockitem', 'archivos.dockitem', 'terminal.dockitem', 'navegador.dockitem']"
  dconf write $P/theme "'RR-Aliados'"
  dconf write $P/hide-mode "'auto'"
  dconf write $P/icon-size 48
  dconf write $P/zoom-enabled true
  dconf write $P/zoom-percent 130
  dconf write $P/position "'bottom'"
  dconf write $P/alignment "'center'"
  dconf write $P/hide-delay 250
  dconf write $P/unhide-delay 100
fi
# Navegador predeterminado de Manuel (el que tenga) para el ícono de Plank
L="$HOME/.config/plank/dock1/launchers"; mkdir -p "$L"
nav=$(xdg-settings get default-web-browser 2>/dev/null || true)
for id in "$nav" firefox_firefox.desktop firefox.desktop firefox-esr.desktop google-chrome.desktop chromium_chromium.desktop chromium.desktop brave-browser.desktop microsoft-edge.desktop; do
  [ -n "$id" ] || continue
  for d in "$HOME/.local/share/applications" /usr/share/applications /var/lib/snapd/desktop/applications /var/lib/flatpak/exports/share/applications "$HOME/.local/share/flatpak/exports/share/applications"; do
    if [ -f "$d/$id" ]; then printf '[PlankDockItemPreferences]\nLauncher=file://%s\n' "$d/$id" >"$L/navegador.dockitem"; break 2; fi
  done
done
if command -v plank >/dev/null && ! pgrep -u "$(id -u)" -x plank >/dev/null; then (setsid plank >/dev/null 2>&1 &); fi

# 6) Listo: este arranque no se vuelve a ejecutar
command -v notify-send >/dev/null && notify-send -i "$HOME/.local/share/icons/rr/simbolo_transparent_mostaza-64.png" "RR ALIADOS" "Tu escritorio RR quedó listo 🎉"
rm -f "$AUTO"
echo "== listo"
