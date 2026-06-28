# Tokyo Night — Hyprland dotfiles

Ricing completo di **EndeavourOS + Hyprland** (Wayland), tema **Tokyo Night**.
Configurazione modulare, animata e coerente su tutto lo stack.

> Questo setup è tarato su un desktop **dual-monitor** (DP-4 2560×1440@60 a
> sinistra · DP-3 1920×1080@144 a destra). Adatta `hypr/conf/monitors.conf` al tuo
> hardware prima dell'uso.

<!-- Aggiungi qui uno screenshot: assets/screenshot.png -->
<!-- ![screenshot](assets/screenshot.png) -->

## Componenti

| Ruolo | Strumento |
|-------|-----------|
| Compositor | **Hyprland** (config modulare in `hypr/conf/`) |
| Barra | **Waybar** (moduli custom: meteo, updates, mpris) |
| Launcher / menu | **rofi** (`SUPER+R`) |
| Terminale | **kitty** |
| Shell | **zsh** + **starship** + **fastfetch** |
| Notifiche | **mako** |
| OSD (volume) | **swayosd** |
| Lockscreen / idle | **hyprlock** + **hypridle** |
| Widget desktop + dashboard | **Quickshell** (`SUPER+D`) |
| Wallpaper animato | **mpvpaper** (video) |
| Clipboard | **cliphist** (`SUPER+SHIFT+V`) |
| Screenshot | **grim** + **slurp** + **swappy** (`SUPER+SHIFT+P`) |
| Color picker | **hyprpicker** (`SUPER+SHIFT+C`) |
| Tema GTK / icone / cursore | Tokyonight-Dark · Papirus-Dark · Bibata-Modern-Classic |

### Dashboard (Quickshell, `SUPER+D`)
Overlay non-modale e trascinabile (posizione persistente), a schede:
- **Audio** — mixer output/input con selettore device (servizio Pipewire nativo)
- **Calendario** — vista mese
- **Sessione** — Blocca / Esci / Riavvia / Spegni (conferma su riavvia/spegni)

## Palette Tokyo Night

| | Hex | | Hex |
|--|--|--|--|
| bg | `#1a1b26` | blue (accento) | `#7aa2f7` |
| bg_dark | `#16161e` | cyan | `#7dcfff` |
| surface | `#292e42` | magenta | `#bb9af7` |
| fg | `#c0caf5` | green | `#9ece6a` |
| comment | `#565f89` | orange | `#ff9e64` |
| selection | `#283457` | red | `#f7768e` |

## ⌨️ Keybind principali

| Combo | Azione |
|-------|--------|
| `SUPER + R` | Launcher (rofi) |
| `SUPER + D` | Dashboard / Control Center |
| `SUPER + Q` | Terminale (kitty) |
| `SUPER + C` | Chiudi finestra attiva |
| `SUPER + F` / `SUPER + V` | Fullscreen / Float |
| `SUPER + CTRL + L` | Lock |
| `SUPER + SHIFT + V` | Clipboard |
| `SUPER + SHIFT + W` | Wallpaper successivo |
| `SUPER + SHIFT + P` | Screenshot (menu) |
| `SUPER + SHIFT + C` | Color picker |

Set completo: `hypr/conf/keybinds.conf`.

## Struttura

```
hypr/        # Hyprland (modulare) + hyprlock/hypridle + scripts
waybar/      # barra + moduli custom + script
quickshell/  # widget desktop + dashboard (QML, Tokyo Night)
kitty/  rofi/  mako/  swayosd/  fastfetch/
gtk-3.0/  gtk-4.0/  wireplumber/  zsh/  starship.toml
```

## Installazione

I dotfiles vivono in `~/dotfiles` e sono collegati a `~/.config` via symlink.

```bash
git clone https://github.com/sonosaturn/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` installa i pacchetti (pacman + AUR via yay, installa yay se manca) e
crea i symlink. È idempotente: i file esistenti non-symlink vengono salvati in `*.bak`
prima del collegamento.

Dopo l'installazione:
- rieffettua il login per entrare in Hyprland;
- i wallpaper-video **non** sono nel repo (binari): mettili in `~/Videos/wallpapers/`;
- adatta `hypr/conf/monitors.conf` al tuo hardware.

### Titlebar finestre (hyprbars)

Le titlebar coi pulsanti (minimizza/max/chiudi) usano il plugin Hyprland **hyprbars**,
installazione una-tantum:

```bash
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprbars
```

Viene caricato al login da `exec-once = hyprpm reload -n` (in `autostart.conf`).
**Dopo ogni aggiornamento di Hyprland** rieseguire `hyprpm update` (ricompila i plugin
per la nuova versione).

---

*Tema: [Tokyo Night](https://github.com/folke/tokyonight.nvim). Font: JetBrainsMono Nerd Font.*
