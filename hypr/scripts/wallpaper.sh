#!/usr/bin/env bash
# ── Wallpaper video con mpvpaper ────────────────────────────────────────
# Modalità:
#   wallpaper.sh <file>            → stesso video su entrambi i monitor
#   wallpaper.sh --span <file>     → un unico video "steso" sui due monitor (crop per schermo)
#   wallpaper.sh --next            → cicla i video in ~/Videos/wallpapers (modalità memorizzata)
#   wallpaper.sh --restore         → riapplica l'ultimo wallpaper (per l'autostart)
#
# Layout monitor (aggiorna qui se cambi disposizione):
LEFT_OUT="DP-4";  LEFT_W=2560;  LEFT_H=1440;  LEFT_X=0
RIGHT_OUT="DP-3"; RIGHT_W=1920; RIGHT_H=1080; RIGHT_X=2560
CANVAS_W=$(( LEFT_W + RIGHT_W ))           # 4480
CANVAS_H=$LEFT_H                            # 1440 (monitor più alto)

WALLDIR="$HOME/Videos/wallpapers"
STATE="$HOME/.cache/wallpaper-state"        # riga1=mode, riga2=file
MPV_OPTS="no-audio --loop-file=inf hwdec=auto --really-quiet"

start_same() {  # $1 = file
  pkill -x mpvpaper 2>/dev/null; sleep 0.3
  nohup mpvpaper -o "$MPV_OPTS panscan=1.0" ALL "$1" >/dev/null 2>&1 &
}

start_span() { # $1 = file → stende il video sui due monitor ritagliando per schermo
  local f="$1"
  # dimensioni sorgente
  local dims w h
  dims=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
         -of csv=s=x:p=0 "$f" 2>/dev/null)
  w=${dims%x*}; h=${dims#*x}
  if [ -z "$w" ] || [ -z "$h" ]; then
    echo "Impossibile leggere le dimensioni di $f" >&2; return 1
  fi
  # scala per COPRIRE il canvas combinato, poi centra
  # s = max(CANVAS_W/w, CANVAS_H/h)  (in virgola mobile via awk)
  read -r ws hs offx offy < <(awk -v w="$w" -v h="$h" -v cw="$CANVAS_W" -v ch="$CANVAS_H" 'BEGIN{
    s1=cw/w; s2=ch/h; s=(s1>s2)?s1:s2;
    ws=int(w*s+0.5); hs=int(h*s+0.5);
    offx=int((ws-cw)/2); offy=int((hs-ch)/2);
    print ws, hs, offx, offy
  }')

  pkill -x mpvpaper 2>/dev/null; sleep 0.3
  # Monitor sinistro: crop della sua porzione (LEFT_W x LEFT_H) a partire da offx
  nohup mpvpaper -o "$MPV_OPTS --vf=scale=${ws}:${hs},crop=${LEFT_W}:${LEFT_H}:$(( offx + LEFT_X )):${offy}" \
    "$LEFT_OUT" "$f" >/dev/null 2>&1 &
  # Monitor destro: crop della sua porzione (RIGHT_W x RIGHT_H)
  nohup mpvpaper -o "$MPV_OPTS --vf=scale=${ws}:${hs},crop=${RIGHT_W}:${RIGHT_H}:$(( offx + RIGHT_X )):${offy}" \
    "$RIGHT_OUT" "$f" >/dev/null 2>&1 &
}

save_state() { mkdir -p "$(dirname "$STATE")"; printf '%s\n%s\n' "$1" "$2" > "$STATE"; }

case "$1" in
  --span)
    [ -f "$2" ] || { echo "File non trovato: $2" >&2; exit 1; }
    start_span "$2" && save_state span "$2" ;;

  --next)
    mapfile -t vids < <(find "$WALLDIR" -maxdepth 1 -type f \
      \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.gif' \) | sort)
    [ ${#vids[@]} -gt 0 ] || { echo "Nessun video in $WALLDIR" >&2; exit 1; }
    cur=$(sed -n 2p "$STATE" 2>/dev/null)
    mode=$(sed -n 1p "$STATE" 2>/dev/null); mode=${mode:-same}
    idx=0; for i in "${!vids[@]}"; do [ "${vids[$i]}" = "$cur" ] && idx=$i; done
    next=${vids[$(( (idx+1) % ${#vids[@]} ))]}
    if [ "$mode" = "span" ]; then start_span "$next"; else start_same "$next"; fi
    save_state "$mode" "$next" ;;

  --restore)
    mode=$(sed -n 1p "$STATE" 2>/dev/null)
    file=$(sed -n 2p "$STATE" 2>/dev/null)
    if [ -f "$file" ]; then
      [ "$mode" = "span" ] && start_span "$file" || start_same "$file"
    else
      # nessuno stato salvato: prendi il primo video disponibile
      first=$(find "$WALLDIR" -maxdepth 1 -type f \
        \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.gif' \) | sort | head -1)
      [ -n "$first" ] && { start_same "$first"; save_state same "$first"; }
    fi ;;

  "" | -h | --help)
    sed -n '2,12p' "$0"; exit 0 ;;

  *)
    [ -f "$1" ] || { echo "File non trovato: $1" >&2; exit 1; }
    start_same "$1" && save_state same "$1" ;;
esac
