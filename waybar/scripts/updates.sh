#!/usr/bin/env bash
# Waybar · conteggio aggiornamenti pacman + AUR (yay)
# Output JSON per Waybar: text + tooltip + class

# Aggiornamenti ufficiali (checkupdates non tocca il db di sistema)
official=$(checkupdates 2>/dev/null)
off_count=$(printf '%s\n' "$official" | grep -c . )

# Aggiornamenti AUR (yay -Qua: query, niente sync/installazione)
aur=$(yay -Qua 2>/dev/null)
aur_count=$(printf '%s\n' "$aur" | grep -c . )

total=$(( off_count + aur_count ))

if [ "$total" -eq 0 ]; then
  # nessun aggiornamento → testo vuoto, classe per nasconderlo via CSS
  printf '{"text":"","tooltip":"Sistema aggiornato","class":"updated","alt":"updated"}\n'
  exit 0
fi

# Tooltip con elenco (limitato per non esplodere)
tooltip=$(printf 'Ufficiali: %s · AUR: %s\n\n%s\n%s' \
  "$off_count" "$aur_count" "$official" "$aur" \
  | head -c 1500 | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"text":"  %s","tooltip":"%s","class":"has-updates","alt":"has-updates"}\n' \
  "$total" "$tooltip"
