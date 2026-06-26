#!/usr/bin/env bash
# Screenshot (Fase 9) — grim + slurp (+ swappy per annotare)
# Salva in ~/Pictures/Screenshots, copia in clipboard, notifica via mako.
#
# Uso:
#   screenshot.sh region   # selezione area  → salva + clipboard
#   screenshot.sh output   # monitor attivo  → salva + clipboard
#   screenshot.sh window   # finestra attiva → salva + clipboard
#   screenshot.sh edit     # selezione area  → apri in swappy (annota)
set -euo pipefail

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
mode="${1:-region}"

# Geometria a seconda della modalità (vuota = tutto lo schermo)
geom=""
case "$mode" in
  region|edit)
    geom="$(slurp)" || exit 1 ;;                       # annulla = ESC → esci
  output)
    geom="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x),\(.y) \(.width)x\(.height)"')" ;;
  window)
    geom="$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" ;;
  *)
    echo "modo sconosciuto: $mode" >&2; exit 2 ;;
esac

grim ${geom:+-g "$geom"} "$file"

if [ "$mode" = edit ]; then
  swappy -f "$file" -o "$file"        # swappy gestisce salvataggio/copia dalla sua UI
fi

wl-copy < "$file"
notify-send -i "$file" "Screenshot" "Salvato in ${file/#$HOME/\~} · copiato in clipboard"
