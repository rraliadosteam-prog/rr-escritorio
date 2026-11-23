#!/usr/bin/env bash
# =====================================================================
#  RR ALIADOS · Instalador del escritorio RR (XFCE con colores RR)
#  Uso:  curl -fsSL https://raw.githubusercontent.com/rraliadosteam-prog/rr-escritorio/main/install.sh | bash
#  - Instala XFCE y lo que falte (pide tu contraseña de sudo una vez).
#  - NO borra ni cambia tu escritorio actual: queda para elegirlo en la pantalla de inicio.
#  - Guarda una copia de tu configuración en ~/rr-escritorio-respaldo/FECHA.
#  - Al final cierra la sesión para que entres al escritorio RR.
#  Variables útiles: RR_NO_LOGOUT=1 (no cerrar sesión)  RR_REF=rama (otra rama del repo)
# =====================================================================
set -euo pipefail

REPO="rraliadosteam-prog/rr-escritorio"
REF="${RR_REF:-main}"

F=$'\e[1;38;2;190;7;109m'; M=$'\e[1;38;2;222;209;22m'; O=$'\e[38;2;151;61;143m'; C=$'\e[38;2;255;255;243m'; N=$'\e[0m'
paso() { printf '\n%s▶ %s%s\n' "$F" "$*" "$N"; }
ok()   { printf '  %s✔%s %s\n' "$M" "$N" "$*"; }
info() { printf '  %s•%s %s\n' "$O" "$N" "$*"; }
aviso(){ printf '  %s⚠ %s%s\n' "$M" "$*" "$N"; }
error(){ printf '\n%s✖ %s%s\n' "$F" "$*" "$N" >&2; exit 1; }

banner() {
  printf '%s\n' "$F═══════════════════════════════════════════════════════$N"
  printf '%s\n' "$M   RR ALIADOS · Escritorio RR$N"
  printf '%s\n' "$C   Temas, íconos, fondos, barra, menú y panel de apps$N"
  printf '%s\n' "$F═══════════════════════════════════════════════════════$N"
}

detectar_distro() {
  [ -r /etc/os-release ] || error "No pude saber qué Linux tienes (falta /etc/os-release)."
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_NOMBRE="${PRETTY_NAME:-Linux}"
  local ids=" ${ID:-} ${ID_LIKE:-} "
  if command -v apt-get >/dev/null && [[ $ids == *" ubuntu "* || $ids == *" debian "* || $ids == *" linuxmint "* || $ids == *" pop "* ]]; then
    PM=apt
  elif command -v apt-get >/dev/null; then PM=apt
  elif command -v dnf >/dev/null; then PM=dnf
  elif command -v pacman >/dev/null; then PM=pacman
  else error "Tu Linux ($DISTRO_NOMBRE) no está soportado. Funciona en Ubuntu, Debian, Linux Mint, Pop!_OS (y a medias en Fedora y Arch)."
  fi
}

pedir_sudo() {
  info "Te voy a pedir tu contraseña de sudo (la de tu usuario) una sola vez."
  if sudo -n true 2>/dev/null; then :
  elif [ -t 0 ]; then sudo -v || error "Sin sudo no puedo instalar los paquetes."
  else sudo -v </dev/tty || error "Sin sudo no puedo instalar los paquetes."
  fi
  ( while true; do sudo -n true 2>/dev/null; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEP=$!
  trap 'kill "${SUDO_KEEP:-0}" 2>/dev/null || true' EXIT
}

instalar_paquetes() {
  case "$PM" in
    apt)
      local base=(xfce4-session xfwm4 xfce4-panel xfdesktop4 xfce4-settings xfconf thunar xfce4-terminal
        xfce4-appfinder xfce4-notifyd xfce4-pulseaudio-plugin xfce4-whiskermenu-plugin xfce4-power-manager
        xfce4-screenshooter mousepad ristretto python3 python3-gi gir1.2-gtk-3.0 gir1.2-wnck-3.0
        xdotool x11-xserver-utils dconf-cli libnotify-bin fontconfig xz-utils tar gtk2-engines-pixbuf
        xdg-utils dbus-x11 network-manager-gnome pavucontrol gtk-update-icon-cache librsvg2-common)
      local extra=(plank papirus-icon-theme xfce4-goodies)
      local APT=(sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)
      "${APT[@]}" update -q </dev/null || aviso "apt update dio un aviso; sigo."
      command -v Xorg >/dev/null || base+=(xorg)
      # Sin "recommends" para no cambiar tu pantalla de inicio actual (gdm, sddm, lightdm...).
      "${APT[@]}" install -y -q --no-install-recommends "${base[@]}" </dev/null || error "No se pudieron instalar los paquetes de XFCE."
      for p in "${extra[@]}"; do
        "${APT[@]}" install -y -q --no-install-recommends "$p" </dev/null >/dev/null 2>&1 && ok "$p" || aviso "No encontré el paquete $p en tu distro; sigo sin él."
      done
      ;;
    dnf)
      sudo dnf install -y @xfce-desktop-environment || sudo dnf groupinstall -y "Xfce Desktop" || error "No se pudo instalar XFCE con dnf."
      for p in xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin plank python3-gobject gtk3 libwnck3 xdotool xrandr dconf libnotify papirus-icon-theme; do
        sudo dnf install -y "$p" >/dev/null 2>&1 && ok "$p" || aviso "No pude instalar $p; sigo sin él."
      done ;;
    pacman)
      sudo pacman -Sy --needed --noconfirm xfce4 xfce4-goodies python-gobject gtk3 libwnck3 xdotool xorg-xrandr dconf libnotify || error "No se pudo instalar XFCE con pacman."
      for p in xfce4-whiskermenu-plugin papirus-icon-theme plank; do
        sudo pacman -S --needed --noconfirm "$p" >/dev/null 2>&1 && ok "$p" || aviso "No pude instalar $p (en Arch puede estar en AUR); sigo sin él."
      done ;;
  esac
  # Si la máquina no tiene ninguna pantalla de inicio gráfica, se pone LightDM.
  if [ ! -e /etc/systemd/system/display-manager.service ] && [ ! -s /etc/X11/default-display-manager ]; then
    aviso "No encontré pantalla de inicio de sesión; instalo LightDM."
    case "$PM" in
      apt) sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q lightdm lightdm-gtk-greeter </dev/null ;;
      dnf) sudo dnf install -y lightdm lightdm-gtk ;;
      pacman) sudo pacman -S --needed --noconfirm lightdm lightdm-gtk-greeter ;;
    esac
    sudo systemctl enable lightdm 2>/dev/null || true
  fi
  ok "Paquetes listos"
}

bajar_repo() {
  local yo; yo="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
  if [ -n "$yo" ] && [ -d "$yo/assets/themes" ]; then SRC="$yo"; ok "Usando los archivos de $SRC"; return; fi
  TMPD="$(mktemp -d)"
  info "Descargando el paquete RR (~25 MB)…"
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/$REF" | tar -xz -C "$TMPD" || error "No pude descargar el paquete RR. Revisa tu internet."
  SRC="$(find "$TMPD" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  ok "Paquete descargado"
}

respaldar() {
  BK="$HOME/rr-escritorio-respaldo/$(date +%Y-%m-%d_%H%M%S)"
  mkdir -p "$BK"
  local p
  for p in .config/xfce4 .config/plank .config/autostart .config/gtk-3.0 .config/Thunar .dmrc; do
    if [ -e "$HOME/$p" ]; then mkdir -p "$BK/$(dirname "$p")"; cp -a "$HOME/$p" "$BK/$p"; fi
  done
  if command -v dconf >/dev/null; then dconf dump /net/launchpad/plank/ >"$BK/plank.dconf" 2>/dev/null || true; fi
  # shellcheck disable=SC2024  # la copia es del usuario, a propósito
  if sudo test -f "/var/lib/AccountsService/users/$USER"; then sudo cat "/var/lib/AccountsService/users/$USER" >"$BK/accountsservice-user" || true; fi
  # La primera copia (tu escritorio original) es la que usa desinstalar.sh; correrlo dos veces no la pisa.
  if [ ! -f "$HOME/rr-escritorio-respaldo/original" ]; then printf '%s\n' "$BK" >"$HOME/rr-escritorio-respaldo/original"; fi
  ok "Copia de tu configuración en $BK"
}

copiar_archivos() {
  local A="$SRC/assets" RRD="$HOME/.local/share/rr-escritorio"
  mkdir -p "$HOME/.themes" "$HOME/.icons" "$HOME/.local/share/icons" "$HOME/.local/share/fonts/rr" \
           "$HOME/.local/share/plank/themes" "$HOME/.local/share/applications" "$HOME/.config/autostart" \
           "$HOME/.config/plank/dock1/launchers" "$RRD/bin" "$RRD/fondos"
  # Temas de ventanas y notificaciones
  for t in RR-Aliados RR-Notify; do rm -rf "$HOME/.themes/$t.rr-tmp"; cp -a "$A/themes/$t" "$HOME/.themes/$t.rr-tmp"; rm -rf "$HOME/.themes/$t"; mv "$HOME/.themes/$t.rr-tmp" "$HOME/.themes/$t"; done
  ok "Tema de ventanas RR-Aliados y notificaciones RR"
  # Íconos RR + Papirus con carpetas fucsia
  cp -a "$A/icons/RR-Oscuro-Iconos" "$A/icons/rr" "$HOME/.local/share/icons/"
  instalar_papirus "$A"
  # Cursor Bibata
  tar -xJf "$A/cursor/Bibata-Modern-Classic.tar.xz" -C "$HOME/.icons/"
  ok "Cursor Bibata"
  # Fuentes
  cp -a "$A/fonts/." "$HOME/.local/share/fonts/rr/"; fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
  ok "Fuentes Inter Tight y Lexend"
  # Plank
  cp -a "$A/plank/RR-Aliados" "$HOME/.local/share/plank/themes/"
  # Programas RR
  cp -a "$A/bin/." "$RRD/bin/"; chmod +x "$RRD/bin/"*
  cp -a "$A/wallpapers/." "$RRD/fondos/"
  sed "s|@HOME@|$HOME|g" "$A/config/xfce4-panel.xml" >"$RRD/xfce4-panel.xml"
  ok "Fondos RR, panel Apps RR, reloj y maximizado de ventanas"

  # Lanzador del panel Apps RR + íconos de Plank
  cat >"$HOME/.local/share/applications/rr-apps.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Apps RR
Comment=Ver todas las aplicaciones
Exec=python3 $RRD/bin/rr-apps.py
Icon=$HOME/.local/share/icons/rr/rr-apps-grid.png
Terminal=false
Categories=Utility;
DESK
  local L="$HOME/.config/plank/dock1/launchers"
  printf '[PlankDockItemPreferences]\nLauncher=file://%s\n' "$HOME/.local/share/applications/rr-apps.desktop" >"$L/rr-apps.dockitem"
  printf '[PlankDockItemPreferences]\nLauncher=file://%s\n' /usr/share/applications/thunar.desktop >"$L/archivos.dockitem"
  printf '[PlankDockItemPreferences]\nLauncher=file://%s\n' /usr/share/applications/xfce4-terminal.desktop >"$L/terminal.dockitem"

  # Arranque automático (solo en XFCE: tu escritorio anterior no se toca)
  auto() { # archivo nombre comando
    printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s\nOnlyShowIn=XFCE;\nNoDisplay=true\nX-GNOME-Autostart-enabled=true\n' "$2" "$3" >"$HOME/.config/autostart/$1.desktop"
  }
  auto rr-plank "Plank RR" "plank"
  auto rr-reloj "Reloj RR" "sh -c 'sleep 8; exec python3 $RRD/bin/rr-reloj.py'"
  auto rr-maximizar "RR Maximizar ventanas" "python3 $RRD/bin/rr-maximizar.py"
  auto rr-fondos "RR Fondos" "$RRD/bin/rr-fondos.sh"
  auto rr-primer-arranque "RR primer arranque" "$RRD/bin/rr-primer-arranque.sh"
  ok "Arranque automático listo (solo dentro de XFCE)"

  # Barra superior y menú: se dejan escritos para el primer inicio de XFCE
  local X="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"; mkdir -p "$X" "$HOME/.config/xfce4/panel"
  cp -f "$RRD/xfce4-panel.xml" "$X/xfce4-panel.xml"
  # Colores, ventanas y notificaciones quedan escritos en disco desde ya (persisten aunque se reinicie antes
  # del primer arranque). Si ya tenías esos archivos, el primer arranque los ajusta con xfconf-query.
  local c
  for c in xsettings xfwm4 xfce4-notifyd; do
    if [ ! -s "$X/$c.xml" ]; then cp -f "$A/config/$c.xml" "$X/$c.xml"; fi
  done
  sed "s|@HOME@|$HOME|g" "$A/config/whiskermenu-4.rc" >"$HOME/.config/xfce4/panel/whiskermenu-4.rc"
  ok "Barra superior negra con menú RR"
}

instalar_papirus() {
  local A="$1" I="$HOME/.local/share/icons" t
  for t in Papirus Papirus-Dark; do
    if [ ! -f "$I/$t/index.theme" ]; then
      if [ -f "/usr/share/icons/$t/index.theme" ]; then
        cp -a "/usr/share/icons/$t" "$I/"
      else
        info "Descargando íconos Papirus desde su página oficial…"
        curl -fsSL https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh \
          | env DESTDIR="$I" EXTRA_THEMES="" sh >/dev/null 2>&1 || { aviso "No pude bajar Papirus; quedan los íconos por defecto."; return 0; }
        break
      fi
    fi
  done
  [ -f "$I/Papirus/index.theme" ] || { aviso "Papirus no quedó instalado; sigo."; return 0; }
  # La caché copiada del sistema queda vieja: se quita y se regenera (si falta la herramienta, GTK lee las carpetas).
  rm -f "$I/Papirus/icon-theme.cache" "$I/Papirus-Dark/icon-theme.cache"
  cp -a "$A/papirus-rr/." "$I/" 2>/dev/null || true
  rm -f "$I/enlaces.tsv"
  local ruta destino
  while IFS=$'\t' read -r ruta destino; do
    if [ -n "$ruta" ] && [ -d "$I/$(dirname "$ruta")" ]; then ln -sfn "$destino" "$I/$ruta"; fi
  done <"$A/papirus-rr/enlaces.tsv"
  for t in Papirus Papirus-Dark RR-Oscuro-Iconos; do gtk-update-icon-cache -f -q "$I/$t" 2>/dev/null || true; done
  ok "Íconos Papirus con carpetas fucsia RR"
}

sesion_xfce() {
  local s=xfce
  [ -f /usr/share/xsessions/xfce.desktop ] || s="$(basename "$(find /usr/share/xsessions -name '*xfce*.desktop' 2>/dev/null | head -n1)" .desktop || true)"
  [ -n "$s" ] || { aviso "No encontré la sesión XFCE en /usr/share/xsessions."; return 0; }
  printf '[Desktop]\nSession=%s\n' "$s" >"$HOME/.dmrc"; chmod 644 "$HOME/.dmrc"
  local U="/var/lib/AccountsService/users/$USER"
  if [ -d /var/lib/AccountsService/users ]; then
    if sudo test -f "$U"; then
      sudo sed -i -e '/^XSession=/d' -e '/^Session=/d' "$U"
      sudo grep -q '^\[User\]' "$U" || echo '[User]' | sudo tee -a "$U" >/dev/null
      sudo sed -i "/^\[User\]/a XSession=$s\nSession=$s" "$U"
    else
      printf '[User]\nSession=%s\nXSession=%s\nSystemAccount=false\n' "$s" "$s" | sudo tee "$U" >/dev/null
    fi
  fi
  ok "XFCE queda como sesión por defecto. Tu escritorio anterior sigue en la pantalla de inicio."
}

cerrar_sesion() {
  if [ "${RR_NO_LOGOUT:-0}" = "1" ]; then info "RR_NO_LOGOUT=1: no cierro la sesión."; return; fi
  printf '\n%s Se cerrará la sesión en 10 s. Guarda tu trabajo (Ctrl+C para cancelar).%s\n' "$M" "$N"
  local i; for i in 10 9 8 7 6 5 4 3 2 1; do printf '\r  %s%2d%s ' "$F" "$i" "$N"; sleep 1; done; echo
  if command -v xfce4-session-logout >/dev/null && [[ ${XDG_CURRENT_DESKTOP:-} == *XFCE* ]]; then xfce4-session-logout --logout --fast && return; fi
  if command -v gnome-session-quit >/dev/null && [[ ${XDG_CURRENT_DESKTOP:-} == *GNOME* || ${XDG_CURRENT_DESKTOP:-} == *Unity* || ${XDG_CURRENT_DESKTOP:-} == *Budgie* ]]; then gnome-session-quit --logout --no-prompt && return; fi
  if command -v qdbus >/dev/null && [[ ${XDG_CURRENT_DESKTOP:-} == *KDE* ]]; then qdbus org.kde.ksmserver /KSMServer logout 0 0 0 && return; fi
  if command -v cinnamon-session-quit >/dev/null && [[ ${XDG_CURRENT_DESKTOP:-} == *Cinnamon* ]]; then cinnamon-session-quit --logout --no-prompt && return; fi
  if command -v mate-session-save >/dev/null && [[ ${XDG_CURRENT_DESKTOP:-} == *MATE* ]]; then mate-session-save --logout && return; fi
  if [ -n "${XDG_SESSION_ID:-}" ]; then loginctl terminate-session "$XDG_SESSION_ID" && return; fi
  aviso "No pude cerrar la sesión sola. Ciérrala tú desde el menú."
}

main() {
  banner
  [ "$(id -u)" -ne 0 ] || error "Ejecútalo con tu usuario normal, sin sudo delante (yo lo pido cuando haga falta)."
  paso "1/6 Revisando tu Linux";        detectar_distro; ok "$DISTRO_NOMBRE (gestor: $PM)"
  paso "2/6 Permiso de administrador";  pedir_sudo
  paso "3/6 Instalando XFCE y lo que falte (puede tardar unos minutos)"; instalar_paquetes
  paso "4/6 Bajando el paquete RR";     bajar_repo
  paso "5/6 Guardando tu configuración y aplicando el escritorio RR"; respaldar; copiar_archivos
  paso "6/6 Dejando XFCE como sesión";  sesion_xfce
  printf '\n%s✅ ¡Listo! Escritorio RR instalado.%s\n' "$M" "$N"
  info "Al entrar, en la pantalla de inicio elige «Xfce Session» (ya queda elegida). Para volver a tu escritorio de antes, elígelo ahí mismo."
  info "Para deshacer: bash ~/.local/share/rr-escritorio/desinstalar.sh"
  cp -f "$SRC/desinstalar.sh" "$HOME/.local/share/rr-escritorio/desinstalar.sh" && chmod +x "$HOME/.local/share/rr-escritorio/desinstalar.sh"
  if [ -n "${TMPD:-}" ]; then rm -rf "$TMPD"; fi
  cerrar_sesion
}

main "$@"
