#!/usr/bin/env bash
# RR ALIADOS: rota los fondos RR cada 5 minutos (solo imágenes).
set -u
DIR="$HOME/.local/share/rr-escritorio/fondos"
mapfile -t imgs < <(find "$DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' \) | sort)
[ "${#imgs[@]}" -gt 0 ] || exit 0
sleep 3
props() {
  xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/backdrop/.*/last-image$'
}
# En una sesión nueva xfdesktop aún no tiene propiedades: se crean por monitor y escritorio.
if [ -z "$(props)" ]; then
  n=$(xfconf-query -c xfwm4 -p /general/workspace_count 2>/dev/null || echo 4)
  for m in $(xrandr --listmonitors 2>/dev/null | awk 'NR>1{print $NF}') 0; do
    for ((w = 0; w < n; w++)); do
      xfconf-query -c xfce4-desktop -n -t string -p "/backdrop/screen0/monitor$m/workspace$w/last-image" -s "${imgs[0]}"
      xfconf-query -c xfce4-desktop -n -t int -p "/backdrop/screen0/monitor$m/workspace$w/image-style" -s 5
    done
  done
fi
i=0
while true; do
  while IFS= read -r p; do
    xfconf-query -c xfce4-desktop -p "$p" -s "${imgs[$i]}"
  done < <(props)
  i=$(( (i + 1) % ${#imgs[@]} ))
  sleep 300
done
