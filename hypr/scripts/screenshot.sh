#!/usr/bin/env bash
# Screenshot (Fase 9) — grim + slurp + swappy + rofi + yad/zenity
#
# Modi DIRETTI (keybind veloci sul tasto Print):
#   screenshot.sh region | output | window | edit
#
# Modo INTERATTIVO (icona waybar / SUPER+SHIFT+P) — stile Snipping Tool:
#   screenshot.sh menu
#     1) rofi: modalità  (Area / Finestra / Schermo)
#     2) rofi: timer      (Subito / 3 / 5 / 10s)
#     3) cattura → yad mostra l'ANTEPRIMA con i pulsanti:
#        Annota (swappy) · Copia · Salva in… (scegli cartella) ·
#        Copia e salva · Rifai cattura · Annulla
set -uo pipefail

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"

# Cattura nella modalità $MODE → scrive su $1. Ritorna !=0 se annullata.
capture() {
  local out="$1" geom=""
  case "$MODE" in
    area)   geom="$(slurp)" || return 1 ;;
    window) geom="$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" ;;
    screen) geom="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x),\(.y) \(.width)x\(.height)"')" ;;
  esac
  grim ${geom:+-g "$geom"} "$out"
}

# Chiede cartella/nome con zenity, copia il file scelto. !=0 se annullato.
finalize_save() {
  local src="$1" dest
  dest="$(zenity --file-selection --save --confirm-overwrite \
            --title="Salva screenshot" \
            --filename="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png")" || return 1
  cp "$src" "$dest"
  notify-send -i "$dest" "Screenshot" "Salvato in ${dest/#$HOME/\~}"
}

# Salvataggio diretto + clipboard (modi veloci)
quick() {
  local f="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
  capture "$f" || exit 0
  wl-copy < "$f"
  notify-send -i "$f" "Screenshot" "Salvato in ${f/#$HOME/\~} · copiato in clipboard"
}

run_menu() {
  # 1+2) modalità e timer in un'unica finestra (default: Area, Subito)
  local sel m t
  sel="$(yad --form --title="Screenshot" --width=360 --center --window-icon=image \
            --field="Modalità:CB" 'Area!Finestra!Schermo intero' \
            --field="Timer:CB"    'Subito!3 secondi!5 secondi!10 secondi' \
            --button="Cattura:0" --button="Annulla:1")" || exit 0
  m="$(printf '%s' "$sel" | cut -d'|' -f1)"
  t="$(printf '%s' "$sel" | cut -d'|' -f2)"
  case "$m" in Area) MODE=area ;; Finestra) MODE=window ;; "Schermo intero") MODE=screen ;; *) exit 0 ;; esac
  case "$t" in "3 "*) sleep 3 ;; "5 "*) sleep 5 ;; "10 "*) sleep 10 ;; esac

  # 3) cattura + conferma con anteprima (loop per "Rifai")
  local tmp; tmp="$(mktemp --suffix=.png)"
  trap 'rm -f "$tmp"' EXIT
  capture "$tmp" || exit 0

  while :; do
    yad --image="$tmp" --title="Screenshot — conferma" \
        --width=820 --height=560 --center --window-icon=image \
        --button="Annota:10" --button="Copia:11" --button="Salva in…:12" \
        --button="Copia e salva:13" --button="Rifai:14" --button="Annulla:1"
    case $? in
      10) swappy -f "$tmp" -o "$tmp" ;;                         # annota → torna al menu
      11) wl-copy < "$tmp"; notify-send -i "$tmp" "Screenshot" "Copiato in clipboard"; break ;;
      12) finalize_save "$tmp" && break ;;                      # zenity annullato → resta nel menu
      13) wl-copy < "$tmp"; finalize_save "$tmp"; break ;;
      14) capture "$tmp" || break ;;
      *)  break ;;                                              # Annulla / chiusura
    esac
  done
}

case "${1:-menu}" in
  menu)   run_menu ;;
  region) MODE=area;   quick ;;
  window) MODE=window; quick ;;
  output) MODE=screen; quick ;;
  edit)   MODE=area; f="$(mktemp --suffix=.png)"; capture "$f" && swappy -f "$f" -o "$f"; rm -f "$f" ;;
  *) echo "uso: $0 [menu|region|window|output|edit]" >&2; exit 2 ;;
esac
