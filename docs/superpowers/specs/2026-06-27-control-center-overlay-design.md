# Fase 9b — Control Center overlay (Quickshell)

> Spec di design. Progetto: ricing Hyprland (Tokyo Night). Data: 2026-06-27.
> Segue la Fase 9a (widget desktop Quickshell). Vedi `~/RICING.md`.

## Obiettivo

Overlay on-demand (toggle **SUPER+D**) che raccoglie i **controlli e le azioni
che NON tengo sempre a schermo**, complementare ai widget glanceable già esistenti
(clock / now-playing / system monitor). Layout **a schede (tab)**, tema Tokyo Night
coerente con i widget, **stessa trasparenza dei widget** (`Theme.panelBg`).

Fuori scope: coda Spotify (rimandata, serve Web API OAuth), slider luminosità
(monitor DP senza backlight → scartata, vedi sotto).

## Decisioni prese (brainstorming)

- **Ruolo**: control center on-demand (controlli/azioni), non dashboard informativa.
- **Layout**: a schede con tab bar in alto, una sezione per volta.
- **Posizione**: sul **monitor attivo** (focus corrente), non fisso su DP-4.
- **Trasparenza**: identica ai widget esistenti → riuso `Theme.panelBg` (nessun nuovo valore).
- **Luminosità DDC**: **scartata**. Monitor esterni DP senza backlight software; l'unica
  via (ddcutil/DDC-CI) è incerta sul supporto, lenta (~100ms/scrittura) e richiede modulo
  i2c + permessi. Eventualmente in futuro.
- **Night light schedule**: orari fissi nel config hyprsunset (attivazione automatica) +
  toggle manuale di override nell'overlay. Niente editor orari in UI (raro cambiarli).

## Sezioni (tab)

### 󰕾 Audio — mixer
- Slider **Master** (default sink) + uno slider **per-app** per ogni stream audio attivo
  (nome app, volume, mute).
- Implementazione **nativa**: `Quickshell.Services.Pipewire` (`Pipewire.defaultAudioSink`,
  `Pipewire.nodes` filtrati su stream audio; `PwObjectTracker` per tenere pronti i nodi).
- Bottone **`pavucontrol`** (già installato) per il resto.

### 󰖔 Luce + 󰂛 DND
Due toggle nella stessa scheda:
- **Luce notturna**: toggle ON/OFF + riga con gli orari automatici (informativa).
  - Daemon `hyprsunset` (extra 0.3.3, **da installare**) in autostart.
  - Schedule via config `~/.config/hypr/hyprsunset.conf` (es. caldo 20:00→07:00).
  - Toggle manuale = override via IPC.
  - ⚠️ **Da confermare in implementazione** (con `hyprsunset --help` / config d'esempio del
    pacchetto installato): comandi IPC e sintassi config. Atteso (0.3.x):
    `hyprctl hyprsunset temperature <K>` / `hyprctl hyprsunset identity` (reset);
    config con blocchi `profile { time = HH:MM; temperature = <K> | identity = true }`
    e `max-gamma`. Adeguare se l'interfaccia reale differisce.
- **DND**: toggle Do Not Disturb di `mako` via `makoctl mode -t do-not-disturb`.
  - Aggiungere `[mode=do-not-disturb]\n  invisible=1` al config mako.
  - Stato letto da `makoctl mode`.

### 󰸗 Calendario
- Mini-calendario del mese in **QML puro** (griglia da `Date`, nessuna dipendenza).
- Frecce mese precedente/successivo; giorno corrente evidenziato (accento `blue`).

### 󰍁 Sessione
- 4 bottoni: **Lock** (`loginctl lock-session` → hyprlock), **Logout**
  (`hyprctl dispatch exit`), **Reboot** (`systemctl reboot`), **Shutdown**
  (`systemctl poweroff`). Riusa l'infrastruttura già configurata (hyprlock/wlogout).

## Architettura

Pattern un-file-per-componente come la Fase 9a. Nuovi file in `~/dotfiles/quickshell/`:

- `ControlCenter.qml` — la finestra overlay + tab bar + switch contenuto. Monta le sezioni.
- `cc/MixerTab.qml` — mixer audio (Pipewire).
- `cc/LightTab.qml` — toggle luce notturna + DND.
- `cc/CalendarTab.qml` — mini calendario.
- `cc/SessionTab.qml` — bottoni sessione.
- (eventuale `cc/Toggle.qml` / `cc/Slider.qml` se i controlli si ripetono — solo se
  davvero riusati, altrimenti inline. YAGNI.)

### Finestra & comportamento
- **PanelWindow** (Quickshell) su layer **Overlay**, ancorata a tutti i bordi ma **sfondo
  trasparente**; dentro, il pannello a schede **centrato**.
- Sfondo = `MouseArea` semitrasparente → **click fuori = chiudi**.
- `WlrLayershell.keyboardFocus: exclusive` quando `visible` → **ESC chiude** (Keys handler).
- `visible` di default `false`; toggle apre/chiude.
- **Monitor attivo**: all'apertura leggo `Quickshell.Hyprland.focusedMonitor.name` e
  assegno alla finestra il `QsScreen` corrispondente.

### Toggle SUPER+D
- `GlobalShortcut` nativo (`Quickshell.Hyprland`), name = `controlcenter`.
- In `keybinds.conf`: `bind = SUPER, D, global, quickshell:controlcenter`.
- SUPER+D risulta **libero** (verificato).

### Stato (letto dai tool, non duplicato)
- Volume/mute: dai nodi Pipewire (reattivo).
- Luce notturna ON/OFF: stato del daemon hyprsunset (o flag interno se l'IPC non espone query).
- DND: `makoctl mode`.
- Polling solo dove serve (DND/luce): `Process`/`Timer` leggero come in SysMonitorWidget.

## Stile
- Riuso `Theme.qml` (palette Tokyo Night, `panelBg`, `border`, `borderWidth`, `radius`,
  `fontFamily`). **Trasparenza = `Theme.panelBg`** (identica ai widget, requisito esplicito).
- Tab attiva evidenziata con accento `blue`/`cyan`.
- Glifi Nerd Font per le icone tab e i controlli (inserire per codepoint: l'editing può
  azzerare i glifi PUA — lezione Fase 9a).

## Dipendenze / file toccati
- **Installare**: `hyprsunset` (extra). Già presenti: mako, pavucontrol, wpctl, Quickshell 0.3.0.
- **Nuovi file**: `quickshell/ControlCenter.qml` + `quickshell/cc/*.qml`; `hypr/hyprsunset.conf`.
- **Modifiche**: `quickshell/shell.qml` (monta l'overlay), `hypr/conf/keybinds.conf` (SUPER+D),
  `mako/config` (modo DND), `hypr/conf/autostart.conf` (hyprsunset daemon).

## Verifica / self-check
- Logica non-banale (calendario: costruzione griglia mese) → self-check `qml6` headless
  (pattern `lib/cpustat_test.qml`): asserisce numero giorni, offset primo giorno, anno
  bisestile.
- Mixer/luce/DND/sessione: verifica funzionale manuale (sono per lo più bind a tool esterni
  e bind reattivi Pipewire).
- `hyprctl reload` 0 errori dopo il keybind; `qs` riavviato senza errori in console.
- Verifica visiva utente (rendering schede, trasparenza == widget, comparsa sul monitor attivo).

## Note
- Coda Spotify: rimandata (MPRIS non espone TrackList; serve Spotify Web API + OAuth).
- Dopo: resta solo la **Fase 10** (palette dinamica, README + push dotfiles, bootstrap).
