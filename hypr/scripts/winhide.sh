#!/usr/bin/env bash
# winhide.sh — minimize/hide della finestra attiva su Hyprland.
#   winhide.sh hide        → nasconde SEMPRE la finestra attiva in special:minimized
#   winhide.sh smart       → SUPER+C: classe in hidelist → nasconde; altrimenti chiude; classe ignota → no-op
#   winhide.sh --self-test → verifica decide()
set -euo pipefail

HIDELIST="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/winhide.list"
WS="special:minimized"

# decide CLASS → stampa: hide | kill | noop   (fail-safe: mai uccidere senza classe certa)
decide() {
    local cls="$1"
    [ -z "$cls" ] && { echo noop; return; }
    if [ -f "$HIDELIST" ] && grep -vE '^[[:space:]]*(#|$)' "$HIDELIST" | grep -qxiF "$cls"; then
        echo hide
    else
        echo kill
    fi
}

hide_active() {
    local addr; addr="$(hyprctl -j activewindow | jq -r '.address // empty')"
    [ -n "$addr" ] && hyprctl dispatch movetoworkspacesilent "$WS,address:$addr"
}

self_test() {
    local tmp; tmp="$(mktemp)"; printf 'Spotify\n# commento\n' > "$tmp"
    HIDELIST="$tmp"
    [ "$(decide Spotify)" = hide ] || { echo "FAIL: Spotify→hide"; exit 1; }
    [ "$(decide firefox)" = kill ] || { echo "FAIL: firefox→kill"; exit 1; }
    [ "$(decide '')"      = noop ] || { echo "FAIL: vuoto→noop"; exit 1; }
    rm -f "$tmp"; echo "PASS winhide"
}

case "${1:-}" in
    --self-test) self_test ;;
    hide)  hide_active ;;
    smart)
        cls="$(hyprctl -j activewindow | jq -r '.class // empty')"
        case "$(decide "$cls")" in
            hide) hide_active ;;
            kill) hyprctl dispatch killactive ;;
            noop) : ;;
        esac
        ;;
    *) echo "uso: winhide.sh {hide|smart|--self-test}" >&2; exit 2 ;;
esac
