#!/usr/bin/env bash
# ── Wallpaper video con mpvpaper ────────────────────────────────────────
# Modalità:
#   wallpaper.sh <file>            → stesso video su entrambi i monitor
#   wallpaper.sh --span <file>     → un unico video "steso" sui due monitor (crop per schermo)
#   wallpaper.sh --next            → cicla i video in ~/Videos/wallpapers (modalità memorizzata)
#   wallpaper.sh --restore         → riapplica l'ultimo wallpaper (per l'autostart)
#
# Layout monitor (aggiorna qui se cambi disposizione/monitor):
#   *_W / *_H   = risoluzione in pixel
#   *_WMM/*_HMM = dimensioni FISICHE dell'area attiva in mm (da spec/EDID)
# Le dimensioni fisiche compensano la diversa DENSITÀ DI PIXEL: DP-3 (23.8" 1080p,
# ~3.64 px/mm) ha pixel più grandi di DP-4 (27" 1440p, ~4.29 px/mm). Allineando solo
# in pixel, l'MSI "ingrandisce" il panorama → i bordi combaciano solo al centro e
# l'offset cresce verso alto/basso. Scalando la fetta di ogni monitor in base ai mm,
# la densità fisica torna uniforme. Disposizione: affiancati in orizzontale, centrati Y.
LEFT_OUT="DP-4";  LEFT_W=2560; LEFT_H=1440; LEFT_WMM=596.74; LEFT_HMM=335.66   # Dell P2723DE 27"
RIGHT_OUT="DP-3"; RIGHT_W=1920; RIGHT_H=1080; RIGHT_WMM=527.04; RIGHT_HMM=296.46 # MSI MAG241C 23.8"

WALLDIR="$HOME/Videos/wallpapers"
STATE="$HOME/.cache/wallpaper-state"        # riga1=mode, riga2=file
MPV_OPTS="no-audio --loop-file=inf hwdec=auto --really-quiet"

start_same() {  # $1 = file
  pkill -x mpvpaper 2>/dev/null; sleep 0.3
  nohup mpvpaper -o "$MPV_OPTS panscan=1.0" ALL "$1" >/dev/null 2>&1 &
}

start_span() { # $1 = file → stende il video sui due monitor, corretto per densità pixel
  local f="$1"
  local dims sw sh
  dims=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
         -of csv=s=x:p=0 "$f" 2>/dev/null)
  sw=${dims%x*}; sh=${dims#*x}
  if [ -z "$sw" ] || [ -z "$sh" ]; then
    echo "Impossibile leggere le dimensioni di $f" >&2; return 1
  fi

  # Crop (cw:ch:cx:cy) per ciascun monitor, calcolati in mm. Il video è mappato sul
  # desktop fisico in modo da COPRIRLO, centrato; ogni monitor ritaglia la sua porzione
  # fisica e poi la scala alla propria risoluzione → densità del panorama uniforme.
  read -r lcw lch lcx lcy rcw rch rcx rcy < <(awk \
    -v sw="$sw" -v sh="$sh" \
    -v lwmm="$LEFT_WMM" -v lhmm="$LEFT_HMM" \
    -v rwmm="$RIGHT_WMM" -v rhmm="$RIGHT_HMM" 'BEGIN{
      T=lwmm+rwmm; H=(lhmm>rhmm)?lhmm:rhmm;        # desktop fisico (mm)
      q1=T/sw; q2=H/sh; q=(q1>q2)?q1:q2; p=1.0/q;   # mm per pixel sorgente (cover) e inverso
      Lm=(sw*q-T)/2.0; Tm=(sh*q-H)/2.0;             # margini di centratura (mm)
      # src_x(phx)=(phx+Lm)*p ; src_y(phy)=(phy+Tm)*p
      lcx=int((0+Lm)*p+0.5);             lcy=int(((H-lhmm)/2.0+Tm)*p+0.5);
      lcw=int(lwmm*p+0.5);               lch=int(lhmm*p+0.5);
      rcx=int((lwmm+Lm)*p+0.5);          rcy=int(((H-rhmm)/2.0+Tm)*p+0.5);
      rcw=int(rwmm*p+0.5);               rch=int(rhmm*p+0.5);
      if(lcx+lcw>sw) lcw=sw-lcx; if(lcy+lch>sh) lch=sh-lcy;
      if(rcx+rcw>sw) rcw=sw-rcx; if(rcy+rch>sh) rch=sh-rcy;
      print lcw,lch,lcx,lcy,rcw,rch,rcx,rcy
  }')

  pkill -x mpvpaper 2>/dev/null; sleep 0.3
  nohup mpvpaper -o "$MPV_OPTS --vf=crop=${lcw}:${lch}:${lcx}:${lcy},scale=${LEFT_W}:${LEFT_H}" \
    "$LEFT_OUT" "$f" >/dev/null 2>&1 &
  nohup mpvpaper -o "$MPV_OPTS --vf=crop=${rcw}:${rch}:${rcx}:${rcy},scale=${RIGHT_W}:${RIGHT_H}" \
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
