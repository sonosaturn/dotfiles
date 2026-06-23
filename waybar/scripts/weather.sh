#!/usr/bin/env bash
# Waybar · meteo attuale via wttr.in (nessun pacchetto extra, solo curl)
# Cambia CITY con la tua città. Lascia vuoto ("") per auto-detect via IP.
CITY="Rome"

# Formato: icona condizione + temperatura (es. "☀️ +22°C")
# %c = icona condizione, %t = temperatura. format=1 → riga compatta.
url="https://wttr.in/${CITY}?format=%c+%t&m"

resp=$(curl -s --max-time 8 "$url" 2>/dev/null)

# Fallback se rete assente o risposta anomala (wttr a volte risponde testo lungo)
if [ -z "$resp" ] || printf '%s' "$resp" | grep -qiE 'unknown|error|html'; then
  printf '{"text":"  --","tooltip":"Meteo non disponibile","class":"weather"}\n'
  exit 0
fi

# Pulizia spazi/escape per JSON
text=$(printf '%s' "$resp" | tr -s ' ' | sed 's/^ *//;s/ *$//' | sed 's/"/\\"/g')

# Tooltip esteso (3 righe) — best effort
tip=$(curl -s --max-time 8 "https://wttr.in/${CITY}?format=%l:+%C+%t+(feels+%f),+vento+%w,+umidità+%h&m" 2>/dev/null \
  | tr -s ' ' | sed 's/"/\\"/g')
[ -z "$tip" ] && tip="$CITY"

printf '{"text":"%s","tooltip":"%s","class":"weather"}\n' "$text" "$tip"
