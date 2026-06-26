#!/usr/bin/env bash
# Color picker (Fase 9) — hyprpicker
# Cattura il colore sotto il cursore, lo copia in clipboard (→ cliphist) e notifica.
set -uo pipefail

col="$(hyprpicker -f hex -b -l -q)" || exit 0   # -b no-fancy (hex pulito), -l minuscolo, -q quiet; ESC → exit non-zero
[ -n "$col" ] || exit 0

wl-copy -- "$col"
notify-send "Color picker" "$col · copiato in clipboard"
