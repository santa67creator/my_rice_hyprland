#!/usr/bin/env bash
#
# install.sh — HyprNova (my_rice_hyprland) installer
#
# Installs packages and symlinks .config/* into $HOME.
# Deliberately does NOT touch system files (greetd, GRUB, Plymouth) or build
# swaync from source — those steps are riskier / machine-specific and are
# left as manual steps printed at the end. See README.md for details.
#
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.hyprnova_backup_$(date +%Y%m%d_%H%M%S)"

CONFIG_DIRS=(hypr waybar kitty yazi swaync wlogout quickshell fastfetch)

echo "==> HyprNova installer"
echo "    Repo:    $DOTFILES_DIR"
echo "    Backup:  $BACKUP_DIR"
echo ""

if ! command -v pacman &> /dev/null; then
    echo "This installer targets Arch Linux (pacman not found). Aborting."
    exit 1
fi

read -rp "Install pacman + AUR packages now? [y/N] " REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    echo "==> Installing pacman packages..."
    sudo pacman -S --needed hyprland hyprlock hyprshot xdg-desktop-portal-hyprland \
        kitty waybar wlogout yazi fastfetch \
        greetd greetd-tuigreet \
        grub plymouth \
        nwg-look papirus-icon-theme \
        network-manager-applet bluez bluez-utils \
        pipewire pipewire-pulse wireplumber pavucontrol \
        brightnessctl playerctl cava \
        ttf-jetbrains-mono-nerd otf-rubik noto-fonts git

    if command -v yay &> /dev/null; then
        AUR_HELPER=yay
    elif command -v paru &> /dev/null; then
        AUR_HELPER=paru
    else
        AUR_HELPER=""
    fi

    if [ -n "$AUR_HELPER" ]; then
        echo "==> Installing AUR packages via $AUR_HELPER..."
        "$AUR_HELPER" -S --needed hyprlauncher hyprshutdown quickshell \
            bibata-cursor-theme-bin ttf-cascadia-code-nerd plymouth-theme-lone-git
    else
        echo "  No AUR helper (yay/paru) found — install these manually:"
        echo "  hyprlauncher hyprshutdown quickshell bibata-cursor-theme-bin ttf-cascadia-code-nerd plymouth-theme-lone-git"
    fi
else
    echo "  Skipping package installation."
fi

echo ""
echo "==> Linking dotfiles into \$HOME/.config ..."
mkdir -p "$BACKUP_DIR"

for name in "${CONFIG_DIRS[@]}"; do
    src="$DOTFILES_DIR/.config/$name"
    dest="$HOME/.config/$name"

    [ -d "$src" ] || continue

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/$name"
        echo "  Backed up: $dest -> $BACKUP_DIR/$name"
    fi

    ln -s "$src" "$dest"
    echo "  Linked:    $dest -> $src"
done

echo ""
echo "==> Fixing hardcoded username in hyprquickpaper config..."
QP_CONFIG="$DOTFILES_DIR/.config/quickshell/hyprquickpaper/config.json"
if [ -f "$QP_CONFIG" ] && grep -q "/home/san/" "$QP_CONFIG"; then
    sed -i "s|/home/san/|$HOME/|g" "$QP_CONFIG"
    echo "  Updated wallpaper_path/cache_path to use \$HOME."
fi

echo ""
echo "✅ Packages + dotfiles done. Old configs (if any) are backed up in:"
echo "   $BACKUP_DIR"
echo ""
echo "⚠️  Manual steps NOT done by this script (system-level / risky to automate):"
echo ""
echo "  1. Notification center widgets — swaync must be built from source to pick"
echo "     up .config/swaync/widgets/*.vala. See README.md, step 5, or remove"
echo "     'buttons-grid' from .config/swaync/config.json to use stock swaync."
echo ""
echo "  2. Login manager — copy greetd/config.toml (+ regreet.toml) to /etc/greetd/"
echo "     and 'sudo systemctl enable greetd.service'. Disable any other display"
echo "     manager first. See README.md, step 6."
echo ""
echo "  3. Boot splash — GRUB + Plymouth setup. See default/Boot_splash.md and"
echo "     README.md, step 7. Back up /etc/default/grub before overwriting it."
echo ""
echo "  4. GTK / icon / cursor theming — open nwg-look and apply the values in"
echo "     GTK-SETTINGS.md (theme, icons, cursor, font)."
echo ""
echo "  5. Monitors — run 'hyprctl monitors' after first login and update"
echo "     .config/hypr/modules/monitors.lua to match your real output names."
echo ""
echo "  6. If you're not on NVIDIA, remove the NVIDIA env vars from"
echo "     .config/hypr/modules/env.lua."
echo ""
echo "Log out and back in through your greeter (or restart Hyprland) to apply."
