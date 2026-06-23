#!/usr/bin/env bash
# Waybar · meteo attuale via wttr.in API JSON (format=j1)
# Temperatura e condizione provengono dallo stesso blocco "current_condition"
# mostrato nell'header della pagina wttr.in → niente discrepanze.
# Cambia CITY con la tua città.
CITY="Rome"

raw=$(curl -s --max-time 8 -A "curl/8" "https://wttr.in/${CITY}?format=j1&m" 2>/dev/null)

printf '%s' "$raw" | CITY="$CITY" python3 - <<'PYEOF'
import sys, json, os

city = os.environ.get("CITY", "")
raw = sys.stdin.read()

# icona di fallback: nf-fa-question (cloud-question non garantito) → usa cloud
FALLBACK = ""  # nf-fa-cloud

def out(text, tooltip):
    print(json.dumps({"text": text, "tooltip": tooltip, "class": "weather"},
                     ensure_ascii=False))

try:
    data = json.loads(raw)
    cur = data["current_condition"][0]
    temp  = cur["temp_C"]
    code  = int(cur["weatherCode"])
    desc  = cur["weatherDesc"][0]["value"]
    feels = cur["FeelsLikeC"]
    wind  = cur["windspeedKmph"]
    hum   = cur["humidity"]
except Exception:
    out(FALLBACK + "  --", "Meteo non disponibile")
    sys.exit(0)

# WWO weatherCode -> glifo nf-weather (Weather Icons)
def icon(c):
    if c == 113:                                   return ""  # sereno/sole
    if c == 116:                                   return ""  # poco nuvoloso
    if c in (119, 122):                            return ""  # nuvoloso/coperto
    if c in (143, 248, 260):                       return ""  # nebbia
    if c in (176, 263, 266, 293, 296, 353):        return ""  # pioggia debole/rovesci
    if c in (299, 302, 305, 308, 356, 359):        return ""  # pioggia forte
    if c in (179, 182, 185, 227, 230, 323, 326,
             329, 332, 335, 338, 368, 371, 374, 377): return ""  # neve
    if c in (200, 386, 389, 392, 395):             return ""  # temporale
    return ""

sign = "" if temp.startswith("-") else "+"
text = f"{icon(code)}  {sign}{temp}°C"
tip  = f"{city}: {desc} {sign}{temp}°C (percepiti {feels}°C), vento {wind} km/h, umidità {hum}%"
out(text, tip)
PYEOF
