#!/usr/bin/env bash
# RR ALIADOS · Deshace el escritorio RR.
# - Vuelve a dejar tu configuración como estaba (usa la última copia en ~/rr-escritorio-respaldo).
# - No borra nada: lo de RR se mueve a ~/rr-escritorio-respaldo/desinstalado-FECHA.
# - No desinstala paquetes (XFCE queda instalado, solo deja de ser la sesión por defecto).
set -uo pipefail
M=$'\e[1;38;2;222;209;22m'; F=$'\e[1;38;2;190;7;109m'; N=$'\e[0m'
ok() { printf '  %s✔%s %s\n' "$M" "$N" "$*"; }
BASE="$HOME/rr-escritorio-respaldo"
BK="$(cat "$BASE/original" 2>/dev/null || true)"
[ -n "$BK" ] && [ -d "$BK" ] || { printf '%sNo encontré la copia de respaldo en %s%s\n' "$F" "$BASE" "$N"; exit 1; }
OUT="$BASE/desinstalado-$(date +%Y-%m-%d_%H%M%S)"; mkdir -p "$OUT"
printf '%s▶ Deshaciendo el escritorio RR (copia: %s)%s\n' "$F" "$BK" "$N"
mover() { if [ -e "$1" ] || [ -L "$1" ]; then mkdir -p "$OUT/$(dirname "${1#"$HOME"/}")"; mv "$1" "$OUT/${1#"$HOME"/}"; fi; }
for a in rr-plank rr-reloj rr-maximizar rr-fondos rr-primer-arranque; do mover "$HOME/.config/autostart/$a.desktop"; done
mover "$HOME/.local/share/applications/rr-apps.desktop"
for p in .config/xfce4 .config/plank .config/gtk-3.0 .config/Thunar .dmrc; do
  if [ -e "$BK/$p" ]; then mover "$HOME/$p"; mkdir -p "$HOME/$(dirname "$p")"; cp -a "$BK/$p" "$HOME/$p"
  elif [ "$p" = ".config/xfce4" ] || [ "$p" = ".config/plank" ] || [ "$p" = ".dmrc" ]; then mover "$HOME/$p"; fi
done
if [ -d "$BK/.config/autostart" ]; then cp -an "$BK/.config/autostart/." "$HOME/.config/autostart/" 2>/dev/null || true; fi
if [ -s "$BK/plank.dconf" ] && command -v dconf >/dev/null; then dconf reset -f /net/launchpad/plank/; dconf load /net/launchpad/plank/ <"$BK/plank.dconf"; fi
ok "Configuración restaurada"
U="/var/lib/AccountsService/users/$USER"
if [ -f "$BK/accountsservice-user" ]; then sudo cp "$BK/accountsservice-user" "$U" && ok "Sesión por defecto restaurada"
elif sudo test -f "$U"; then sudo sed -i -e '/^XSession=xfce/d' -e '/^Session=xfce/d' "$U" && ok "XFCE ya no es la sesión por defecto"; fi
mover "$HOME/.local/share/rr-escritorio"
mv "$BASE/original" "$OUT/original-usado"
ok "Archivos RR movidos a $OUT (temas, íconos y fuentes quedan instalados pero sin usar)"
printf '%s✅ Listo. Cierra sesión y entra con tu escritorio de siempre.%s\n' "$M" "$N"
