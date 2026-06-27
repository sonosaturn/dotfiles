#!/usr/bin/env bash
# Bootstrap del ricing Tokyo Night — EndeavourOS/Arch + Hyprland.
# Installa i pacchetti (pacman + AUR via yay) e collega i dotfile con symlink.
# Idempotente: i file esistenti non-symlink vengono salvati in *.bak prima del link.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Pacchetti ──────────────────────────────────────────────
OFFICIAL=(
    hyprland hyprlock hypridle hyprpicker          # compositor & utility
    waybar rofi mako swayosd                        # barra / launcher / notifiche / osd
    kitty zsh zsh-autosuggestions zsh-syntax-highlighting starship fastfetch
    quickshell                                      # widget desktop & dashboard
    mpv                                             # player (per il wallpaper animato)
    grim slurp swappy jq                            # screenshot
    cliphist wl-clipboard                           # clipboard manager
    pavucontrol wireplumber playerctl               # audio
    papirus-icon-theme ttf-jetbrains-mono-nerd      # icone & font
    polkit-gnome                                    # agente polkit
)
AUR=(
    mpvpaper                                        # wallpaper video Wayland-native
    tokyonight-gtk-theme-git                        # tema GTK
    bibata-cursor-theme-bin                         # cursore (con hyprcursor)
)

# ── Helper ─────────────────────────────────────────────────
info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

ensure_yay() {
    command -v yay >/dev/null 2>&1 && return
    info "yay non trovato: lo installo dall'AUR…"
    sudo pacman -S --needed --noconfirm git base-devel
    local tmp; tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    ( cd "$tmp/yay" && makepkg -si --noconfirm )
    rm -rf "$tmp"
}

# crea un symlink src→dest, salvando un eventuale file/dir reale preesistente
link() {
    local src="$1" dest="$2"
    if [ -L "$dest" ]; then rm -f "$dest"
    elif [ -e "$dest" ]; then
        info "backup $dest → $dest.bak"
        mv "$dest" "$dest.bak"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    printf '   %s → %s\n' "$dest" "$src"
}

# ── 1. Pacchetti ───────────────────────────────────────────
info "Installo i pacchetti ufficiali…"
sudo pacman -S --needed --noconfirm "${OFFICIAL[@]}"

ensure_yay
info "Installo i pacchetti AUR…"
yay -S --needed --noconfirm "${AUR[@]}"

# ── 2. Symlink ─────────────────────────────────────────────
info "Collego i dotfile…"
CONFIG_DIRS=(hypr waybar quickshell kitty rofi mako swayosd swaync
             fastfetch gtk-3.0 gtk-4.0 wireplumber)
for d in "${CONFIG_DIRS[@]}"; do
    [ -e "$DOTFILES/$d" ] && link "$DOTFILES/$d" "$HOME/.config/$d"
done
link "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/zsh/zshrc"     "$HOME/.zshrc"

# ── 3. Shell di default ────────────────────────────────────
if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    info "Imposto zsh come shell di default (chsh)…"
    chsh -s "$(command -v zsh)" || info "chsh fallito: eseguilo a mano."
fi

cat <<EOF

✅ Fatto.
   • Rieffettua il login per entrare in Hyprland con la nuova config.
   • I wallpaper-video NON sono nel repo: mettili in ~/Videos/wallpapers/.
   • Adatta ~/.config/hypr/conf/monitors.conf al tuo hardware.
EOF
