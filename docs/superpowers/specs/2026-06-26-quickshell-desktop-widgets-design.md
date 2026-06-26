# Fase 9a — Widget desktop Quickshell (Tokyo Night)

> Spec di design. Parte del ricing Hyprland (vedi `~/RICING.md`, Fase 9).
> Data: 2026-06-26 · Toolkit: **Quickshell 0.3.0** (QML/Qt6).

## Obiettivo

Tre widget fissi sul desktop del monitor **DP-4** (2560×1440), sopra il
wallpaper video (mpvpaper) e sotto le finestre:

1. **Orologio + data** grande.
2. **Now-playing** con copertina, controlli e barra di avanzamento (MPRIS/playerctl, funziona con Spotify).
3. **System monitor** compatto: CPU%, RAM%, GPU% + temperature CPU/GPU.

Estetica "cozy": pannelli arrotondati, semi-trasparenti, tema **Tokyo Night**.
Calendario, audio visualizer, meteo a più giorni e l'overlay a schede sono
**fuori scope** — vanno nella Fase 9b (overlay `SUPER+D`).

## Vincoli e decisioni (dal brainstorming)

- **Convivenza con Waybar**: Quickshell NON tocca la barra. Waybar resta la
  barra di sistema. Quickshell fa solo i widget desktop (9a) e poi l'overlay (9b).
- **Solo DP-4**: tutti i widget sul monitor grande. DP-3 resta pulito.
- **Layer `bottom`**: i widget si vedono sul desktop e vengono coperti quando
  si aprono/affiancano finestre (comportamento desktop-widget classico).
  Nessuna zona di esclusione (non riservano spazio).
- **No Qt theming nativo**: i widget sono disegnati in QML, quindi il tema è
  definito nella palette QML. Il rinvio di Kvantum/qt6ct della Fase 7 resta valido.

## Architettura

```
~/dotfiles/quickshell/         (symlink → ~/.config/quickshell/)
├── shell.qml                  entry: ShellRoot, istanzia i 3 widget su DP-4
├── Theme.qml                  singleton: palette Tokyo Night + costanti stile
├── ClockWidget.qml            PanelWindow: ora + data
├── NowPlayingWidget.qml       PanelWindow: MPRIS (copertina, controlli, seek bar)
├── SysMonitorWidget.qml       PanelWindow: CPU/RAM/GPU + temp
└── lib/
    ├── CpuStat.qml            calcolo CPU% da delta /proc/stat (logica isolata)
    └── (helper se servono)
```

Ogni widget è un `PanelWindow` (Quickshell.Wayland) indipendente:
- `screen`: l'oggetto schermo il cui `name == "DP-4"` (lookup in shell.qml;
  se DP-4 non c'è, fallback al primo schermo — il setup è plug stabile).
- `WlrLayershell.layer: WlrLayer.Bottom`, `exclusionMode: ExclusionMode.Ignore`.
- `color: "transparent"`; il pannello visibile è un `Rectangle` interno
  arrotondato e semi-trasparente.
- ancoraggio + margini per posizionarlo (vedi Layout).

### Theme.qml (singleton)

Palette Tokyo Night (da `~/RICING.md`): bg `#1a1b26`, bg_dark `#16161e`,
surface `#292e42`/`#414868`, fg `#c0caf5`, subtext `#a9b1d6`,
comment `#565f89`, blue `#7aa2f7`, cyan `#7dcfff`, teal `#2ac3de`,
magenta `#bb9af7`, green `#9ece6a`, orange `#ff9e64`, yellow `#e0af68`,
red `#f7768e`.

Costanti stile condivise: `radius: 18`, `panelBg` (= bg con alpha ~0.85),
`border` (blue), `borderWidth`, `font` ("JetBrainsMono Nerd Font"),
spaziature. Riusato anche dall'overlay 9b.

## Layout su DP-4 (modificabile)

```
┌────────────────────────────────────────────────────────┐
│  ┌──────────────┐                          ┌─────────┐  │
│  │ SYS MONITOR  │  (top-left)              │  09:42  │  │ clock (top-right)
│  └──────────────┘                          └─────────┘  │
│  ┌────────────────────────┐                            │
│  │ NOW PLAYING            │  (bottom-left)             │
│  └────────────────────────┘                            │
└────────────────────────────────────────────────────────┘
```

- **Clock**: top-right, margini ~40px. Ora 24h grande (~64px), data IT sotto
  (giorno settimana + numero + mese), accento blue/cyan.
- **SysMonitor**: top-left, margini ~40px. Righe CPU/RAM/GPU con mini-barra
  + percentuale; riga temperature CPU/GPU in °C.
- **NowPlaying**: bottom-left, margini ~40px. Copertina (~80px) a sinistra;
  a destra titolo + artista, riga controlli ⏮ ⏯ ⏭, seek bar con tempo
  corrente/totale.

## Flusso dati

| Widget | Fonte | Meccanismo | Poll |
|--------|-------|------------|------|
| Clock | `SystemClock` (Quickshell) | binding reattivo | 1s (sec) |
| NowPlaying | `Mpris` (Quickshell.Services.Mpris) | player attivo → metadata/posizione/stato; controlli via metodi del player | evento + 1s per la seek bar |
| Copertina | `trackArtUrl` MPRIS | `Image { source: artUrl }` (Spotify = URL https, QML lo carica diretto) | — |
| CPU% | `/proc/stat` | `FileView` + `CpuStat.qml` (delta idle/total) | 2s |
| RAM% | `/proc/meminfo` | `FileView`, `(MemTotal-MemAvailable)/MemTotal` | 2s |
| GPU% + temp | `nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits` | `Process` | 2s |
| CPU temp | `/sys/class/hwmon/hwmon3/temp*_input` (coretemp, Package id 0) | `FileView` | 2s |

NB: `hwmon3 == coretemp` verificato oggi, ma l'indice hwmon può cambiare al
riavvio. La logica risolve il path cercando il `name == "coretemp"` tra
`/sys/class/hwmon/hwmon*/`, non l'indice fisso. (`ponytail:` se diventa
fragile, passare a `sensors -j`.)

## Gestione errori

- **Nessun player MPRIS attivo** → NowPlaying mostra placeholder "Niente in
  riproduzione", controlli disabilitati.
- **Copertina mancante / URL non caricabile** → riquadro placeholder (icona nota musicale).
- **`nvidia-smi` assente o errore** → GPU% e temp GPU mostrano `--`.
- **coretemp non trovato** → temp CPU mostra `--`.
- **DP-4 non presente** → fallback al primo schermo disponibile.

Tutti i fallback sono silenziosi (no crash, no spam log).

## Avvio

- Autostart Hyprland: `exec-once = qs` in `~/dotfiles/hypr/conf/autostart.conf`
  (Quickshell carica `~/.config/quickshell/shell.qml` di default).
- Reload durante lo sviluppo: Quickshell fa hot-reload al salvataggio dei .qml.

## Test / verifica

- **Self-check logica CPU%** (unica logica non banale): script che alimenta
  `CpuStat` con due snapshot noti di `/proc/stat` e verifica la % attesa
  (`assert`). Implementazione minima: `qs`-eval o un piccolo script awk
  equivalente con asserzione — il più piccolo controllo che fallisce se il
  calcolo del delta si rompe. Niente framework.
- **Verifica visiva**: `qs` parte senza errori, i 3 widget compaiono su DP-4,
  now-playing reagisce a Spotify, le percentuali si muovono. Confermata dall'utente.

## Fuori scope (→ Fase 9b)

Overlay `SUPER+D` a schede (Dashboard/Media/Performance/Weather), calendario,
meteo Open-Meteo multi-giorno, audio visualizer, avatar+uptime, to-do/GitHub.
Il `Theme.qml` e i componenti di 9a saranno riusati dall'overlay.
