# 🌊 HyprNova

**`my_rice_hyprland`** — a Hyprland + Arch Linux desktop configuration built around a **Gruvbox Material Dark / teal‑glass** aesthetic, from boot splash to lock screen.

This repo is both a personal daily driver and a build log: every dotfile here is something I actually use, and this README exists so that *future me* (or anyone else who wants to steal a piece of it) can rebuild the whole thing without having to reverse‑engineer it from scratch.

> Uses Hyprland's newer **Lua configuration API** (`hl.bind`, `hl.config`, `hl.monitor`, …) instead of the classic `hyprland.conf` syntax — make sure your Hyprland build supports it (see [Requirements](#-requirements)).

---

## 📑 Table of contents

- [Preview](#-preview)
- [What's inside](#-whats-inside)
- [Companion repo: terminal (zsh / vim / starship)](#-companion-repo-terminal-zsh--vim--starship)
- [Color palette](#-color-palette)
- [Requirements](#-requirements)
- [Installation](#-installation)
  - [Quick install](#quick-install)
  - [1. Base packages](#1-install-base-packages)
  - [2. Get the dotfiles](#2-get-the-dotfiles)
  - [3. Fix hardcoded paths](#3-fix-hardcoded-paths)
  - [4. GTK / icons / cursor](#4-gtk--icons--cursor-theming)
  - [5. Notification center (swaync, from source)](#5-notification-center-swaync-from-source)
  - [6. Login screen (greetd)](#6-login-screen-greetd--tuigreet)
  - [7. Boot splash (GRUB + Plymouth)](#7-boot-splash-grub--plymouth)
  - [8. First boot](#8-first-boot)
- [Keybindings](#-keybindings)
- [Repository structure](#-repository-structure)
- [Customizing](#-customizing)
- [Known quirks / TODO](#-known-quirks--todo)
- [License](#-license)

---

## 🖼 Preview

<img width="1920" height="1080" alt="2026-08-19-113211_hyprshot" src="https://github.com/user-attachments/assets/27af79ea-cffb-4ae0-9126-18b5b6398dcf" />  

<img width="1920" height="1080" alt="2026-08-18-125344_hyprshot" src="https://github.com/user-attachments/assets/4eb29449-3f5c-45b3-83b6-aca6ea85239c" />

<img width="1920" height="1080" alt="2026-08-19-120326_hyprshot" src="https://github.com/user-attachments/assets/97b130ce-1b6d-4133-b177-faeba46a42c1" />


The included wallpaper set lives in [`.config/quickshell/hyprquickpaper/Wallpapers`](.config/quickshell/hyprquickpaper/Wallpapers) and is cycled through by `hyprquickpaper`.

---

## 📦 What's inside

| Component | Tool | Notes |
|---|---|---|
| Compositor | [Hyprland](https://hyprland.org) | Config written in **Lua**, split into modules under `.config/hypr/modules/` |
| Bar | [Waybar](https://github.com/Alexays/Waybar) | Gruvbox Material color import, clock/workspaces/network/audio/battery/cava |
| App launcher | `hyprlauncher` | Official Hypr‑ecosystem launcher (built on `hyprtoolkit`) |
| Power menu | `hyprshutdown` | Hypr‑ecosystem power menu, themed via `hyprtoolkit.conf` |
| Lock screen | `hyprlock` | Screenshot‑blur background |
| Logout menu | `wlogout` | Custom CSS, 4‑button grid layout |
| Notifications | `swaync` (patched) | Custom Vala widgets (icon+caption buttons‑grid, menubar) — **built from source**, see below |
| Wallpaper | `quickshell` (`hyprquickpaper`) | QML wallpaper picker/daemon, bound to `SUPER + W` |
| Terminal | `kitty` | JetBrainsMono Nerd Font Mono, custom color scheme |
| File manager | `yazi` | Custom theme + `dualpane` and `split-tabs` plugins |
| System info | `fastfetch` | Custom anime ASCII logos, boxed hardware/software layout |
| Screenshots | `hyprshot` | Region / window / output capture |
| Login manager | `greetd` + `tuigreet` | TUI greeter, launches Hyprland directly |
| Boot splash | GRUB + Plymouth (`lone` theme) | System‑level, documented in [`default/Boot_splash.md`](default/Boot_splash.md) |
| GTK theming | `nwg-look` | Documented in [`GTK-SETTINGS.md`](GTK-SETTINGS.md) |

---

## 🧩 Companion repo: terminal (zsh / vim / starship)

This repo covers the **desktop** (compositor, bar, lock/logout, notifications). The **inside-the-terminal** half of the setup — what actually runs inside `kitty` — lives in a separate repo:

**➡️ [santa67creator/my_requie](https://github.com/santa67creator/my_requie)**

| File | Description |
|---|---|
| `.zshrc` | Zsh on Oh My Zsh, with `zsh-autosuggestions` + `zsh-syntax-highlighting`, prompt rendered via Starship |
| `.vimrc` | Vim: syntax highlighting, relative line numbers, NERDTree (`Ctrl+b`), sane indent/tabs |
| `.config/starship.toml` | "Caelestia" blue/purple Starship theme — user/host, path, git status, language versions, Docker context, memory, command duration |

It ships its own `install.sh` (installs Oh My Zsh, plugins, Starship, vim-plug, then symlinks the three files above with an automatic backup) — grab it separately:

```bash
git clone https://github.com/santa67creator/my_requie.git ~/my_requie
cd ~/my_requie
chmod +x install.sh
./install.sh
```

Same Nerd Font requirement as this repo (`JetBrainsMono Nerd Font` — already installed if you followed [step 1](#1-install-base-packages) below), so prompt/NERDTree icons render correctly.

---

## 🎨 Color palette

Gruvbox Material Dark, teal accent. Defined in [`.config/waybar/colors/gruvbox-material.css`](.config/waybar/colors/gruvbox-material.css) and reused (by value) across Waybar, swaync and wlogout.

| Name | Hex | Swatch |
|---|---|---|
| `bg0` | `#1d2021` | Base background |
| `bg1` | `#282828` | Panels / cards |
| `bg2` | `#262a2b` | — |
| `bg3` | `#45403d` | Borders / dividers |
| `bg4` | `#2f3436` | — |
| `fg` | `#d4be98` | Foreground text |
| `red` | `#ea6962` | Errors / mute |
| `orange` | `#e78a4e` | — |
| `yellow` | `#d8a657` | Warnings / battery |
| `green` | `#a9b665` | Success / PC info |
| `aqua` | `#89b482` | — |
| **`blue` (teal accent)** | **`#7daea3`** | Primary accent, active border |
| `purple` | `#d3869b` | — |
| `grey0`–`grey2` | `#a89984` / `#928374` / `#7c6f64` | Muted text |

GTK / cursor / icon theme values (see [`GTK-SETTINGS.md`](GTK-SETTINGS.md) for the full breakdown):

```ini
gtk-theme-name=Gruvbox-Material-Dark
gtk-icon-theme-name=Papirus
gtk-cursor-theme-name=Bibata-Modern-Amber
gtk-cursor-theme-size=24
gtk-font-name=Rubik Bold 11.3
```

---

## ✅ Requirements

- **Arch Linux** (or an Arch‑based distro) on a UEFI system with **GRUB**.
- **Hyprland with Lua config support.** The configs in this repo (`hl.bind(...)`, `hl.config({...})`, etc.) target the newer Lua‑based config format — a fairly recent Hyprland build. If your `hyprland.lua` fails to parse, your Hyprland is too old; pull the latest `hyprland` / `hyprland-git` package.
- An **AUR helper** (`yay` or `paru`) — several pieces below only exist on the AUR.
- NVIDIA users: this config sets `LIBVA_DRIVER_NAME=nvidia` and `__GLX_VENDOR_LIBRARY_NAME=nvidia` in `env.lua`. **Remove those lines if you're on AMD/Intel-only**, or Wayland apps may fail to start.

---

## 🚀 Installation

### Quick install

```bash
git clone https://github.com/santa67creator/my_rice_hyprland.git
cd my_rice_hyprland
chmod +x install.sh
./install.sh
```

`install.sh` will (optionally) install the pacman + AUR packages, back up any existing `~/.config/{hypr,waybar,kitty,yazi,swaync,wlogout,quickshell,fastfetch}`, symlink this repo's versions into place, and fix the hardcoded username in the wallpaper picker config.

**It intentionally does *not* touch system files** — building `swaync` from source, `greetd`, GRUB/Plymouth, GTK theming via `nwg-look`, and setting your real monitor names are all left for you to do by hand (the script prints exactly what's left when it finishes). Read through the manual steps below at least once, even if you use the script — several of them are one-time, system-level, and worth understanding before you run them.

### Manual installation, step by step

If you'd rather skip the script entirely, or want to understand what it's doing:

### 1. Install base packages

```bash
# Core
sudo pacman -S hyprland hyprlock hyprshot xdg-desktop-portal-hyprland \
                kitty waybar wlogout yazi fastfetch \
                greetd greetd-tuigreet \
                grub plymouth \
                nwg-look papirus-icon-theme \
                network-manager-applet bluez bluez-utils \
                pipewire pipewire-pulse wireplumber pavucontrol \
                brightnessctl playerctl cava \
                ttf-jetbrains-mono-nerd otf-rubik noto-fonts git

# AUR (hyprlauncher / hyprshutdown are part of the official Hypr ecosystem;
# quickshell powers the wallpaper picker; the rest are theming assets)
yay -S hyprlauncher hyprshutdown quickshell \
       bibata-cursor-theme-bin ttf-cascadia-code-nerd \
       plymouth-theme-lone-git
```

> `awww-daemon`, used as a wallpaper backend in `autostart.lua`, isn't a package I could verify by that exact name — double‑check it (it may need to be `swww-daemon`, or whatever you swap in as your wallpaper daemon) before relying on autostart.

### 2. Get the dotfiles

`install.sh` (see [Quick install](#quick-install)) does the backup + symlink dance below for you. Manual equivalent:

```bash
git clone https://github.com/santa67creator/my_rice_hyprland.git
cd my_rice_hyprland

# Back up anything that already exists before overwriting it, then symlink
# (symlinks, not copies, so `git pull` updates apply instantly)
mkdir -p ~/.config-backup
for d in hypr waybar kitty yazi swaync wlogout quickshell fastfetch; do
  [ -d "$HOME/.config/$d" ] && mv "$HOME/.config/$d" ~/.config-backup/
  ln -s "$PWD/.config/$d" "$HOME/.config/$d"
done
```

### 3. Fix hardcoded paths

The wallpaper daemon config still points at my home directory. Update it to yours:

```bash
sed -i "s|/home/san/|$HOME/|g" ~/.config/quickshell/hyprquickpaper/config.json
```

### 4. GTK / icons / cursor theming

Follow [`GTK-SETTINGS.md`](GTK-SETTINGS.md): open `nwg-look`, set theme `Gruvbox-Material-Dark`, icons `Papirus`, cursor `Bibata-Modern-Amber` (size 24), font `Rubik Bold 11.3`, and enable "prefer dark theme." `nwg-look` writes `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini` and `~/.gtkrc-2.0` for you.

### 5. Notification center (swaync, from source)

`.config/swaync/widgets/*.vala` are **source patches**, not stock swaync — they add an icon+caption buttons‑grid widget and a custom menu bar. Stock swaync from the repos won't pick these up. To use them:

```bash
git clone https://github.com/ErikReider/SwayNotificationCenter.git
cd SwayNotificationCenter
# copy the custom widgets over the stock ones
cp /path/to/my_rice_hyprland/.config/swaync/widgets/*.vala src/widgets/
# register any new widget files in meson.build if they aren't already listed
meson setup build
ninja -C build
sudo ninja -C build install
```

If you'd rather not build from source, skip this step and just remove `"buttons-grid"` from the `widgets` list in `.config/swaync/config.json` — the rest of swaync works fine stock.

### 6. Login screen (greetd + tuigreet)

```bash
sudo cp greetd/config.toml /etc/greetd/config.toml
sudo cp greetd/regreet.toml /etc/greetd/regreet.toml   # only needed if you use regreet instead of tuigreet
sudo systemctl enable greetd.service
# disable any other display manager (gdm/sddm/lightdm) first!
```

The greeter launches Hyprland directly via `--cmd start-hyprland`. Make sure a `start-hyprland` command/script exists on your `$PATH` (or swap it for `Hyprland`/your own launch script).

### 7. Boot splash (GRUB + Plymouth)

This part lives in system files, not dotfiles — full steps are in [`default/Boot_splash.md`](default/Boot_splash.md). Short version:

```bash
sudo pacman -S plymouth
yay -S plymouth-theme-lone-git
sudo plymouth-set-default-theme -R lone

# add the plymouth hook to /etc/mkinitcpio.conf, right after udev:
# HOOKS=(base udev plymouth autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)

# back up your existing /etc/default/grub first, then compare against this repo's default/grub
sudo cp /etc/default/grub /etc/default/grub.bak
sudo cp default/grub /etc/default/grub   # review the diff before overwriting — GRUB_CMDLINE assumes NVIDIA (nvidia_drm.modeset=1)

sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 8. First boot

Reboot, log in through `tuigreet`, and Hyprland should start with the bar, wallpaper daemon and notification daemon autostarted (see `.config/hypr/modules/autostart.lua`). Run `hyprctl monitors` and adjust `.config/hypr/modules/monitors.lua` to match your actual monitor names — mine are hardcoded to `eDP-1` + `HDMI-A-1`.

---

## ⌨️ Keybindings

`mainMod` = `SUPER`. Full source: [`.config/hypr/modules/binds.lua`](.config/hypr/modules/binds.lua).

| Bind | Action |
|---|---|
| `SUPER + Q` | Open terminal (`kitty`) |
| `SUPER + C` | Close focused window |
| `SUPER + E` | Open file manager (`kitty -e yazi`) |
| `SUPER + R` | App launcher (`hyprlauncher`) |
| `SUPER + M` | Power menu (`hyprshutdown`) |
| `SUPER + L` | Lock screen (`hyprlock`) |
| `SUPER + SHIFT + L` | Logout menu (`wlogout -b 4`) |
| `SUPER + N` | Toggle notification center (`swaync-client -t -sw`) |
| `SUPER + W` | Wallpaper picker (`quickshell -c hyprquickpaper`) |
| `SUPER + V` | Toggle floating |
| `SUPER + P` | Pseudo‑tile |
| `SUPER + J` | Toggle split (dwindle layout only) |
| `SUPER + ←/→/↑/↓` | Move focus |
| `SUPER + [0–9]` | Switch to workspace 1–10 |
| `SUPER + SHIFT + [0–9]` | Move window to workspace 1–10 |
| `SUPER + S` | Toggle scratchpad (`special:magic`) |
| `SUPER + SHIFT + S` | Move window to scratchpad |
| `SUPER + scroll` | Cycle workspaces |
| `SUPER + LMB drag` / `SUPER + RMB drag` | Move / resize window |
| `SUPER + KP_End` / `+SHIFT` | Move column right / left (scrolling layout) |
| `SUPER + KP_Down` / `+SHIFT` | Swap column right / left |
| `SUPER + KP_Next` / `+SHIFT` | Consume / expel window (scrolling layout) |
| `PRINT` | Screenshot region |
| `SHIFT + PRINT` | Screenshot window |
| `SUPER + PRINT` | Screenshot output |
| Volume / Brightness / Media keys | `wpctl`, `brightnessctl`, `playerctl` (works out of the box on laptop function keys) |

Default layout is Hyprland's **scrolling** layout (PaperWM‑style columns), not dwindle — see `layout.lua`.

---

## 🗂 Repository structure

```
.
├── .config/
│   ├── hypr/
│   │   ├── hyprland.lua            # entry point, requires all modules below
│   │   ├── modules/
│   │   │   ├── monitors.lua        # output layout + per-monitor workspaces
│   │   │   ├── binds.lua           # keybindings
│   │   │   ├── autostart.lua       # startup apps (bar, notif daemon, wallpaper, cursor)
│   │   │   ├── env.lua             # env vars (Wayland/Qt/NVIDIA)
│   │   │   ├── decorations.lua     # gaps, borders, blur, shadows, animation curves
│   │   │   ├── layout.lua          # scrolling / dwindle / master tuning
│   │   │   ├── misc.lua            # wallpaper/logo toggles
│   │   │   ├── input.lua           # keyboard, touchpad, gestures, per-device sensitivity
│   │   │   └── windowrules.lua     # window & layer rules (XWayland fixes, swaync blur, etc.)
│   │   ├── hyprlock.conf           # lock screen
│   │   ├── hyprlauncher.conf       # app launcher
│   │   ├── hyprtoolkit.conf        # shared theme for Hypr-ecosystem GUI apps
│   │   └── scripts/now-playing.sh
│   ├── waybar/                     # bar: config.jsonc, style.css, colors/gruvbox-material.css
│   ├── swaync/                     # notification center + custom Vala widgets (see install step 5)
│   ├── wlogout/                    # logout menu layout + style.css
│   ├── quickshell/hyprquickpaper/  # QML wallpaper picker + wallpaper set
│   ├── kitty/                      # terminal config + color scheme
│   ├── yazi/                       # file manager theme, keymap, plugins
│   └── fastfetch/                  # config.jsonc + custom ASCII logos
├── greetd/                         # config.toml (tuigreet) + regreet.toml — copy to /etc/greetd/
├── default/
│   ├── grub                        # reference /etc/default/grub
│   └── Boot_splash.md              # GRUB + Plymouth setup guide
├── GTK-SETTINGS.md                 # nwg-look GTK/icon/cursor theming reference
└── README.md
```

---

## 🛠 Customizing

- **Colors:** edit `.config/waybar/colors/gruvbox-material.css` and mirror the hex values into `.config/swaync/style.css` and `.config/wlogout/style.css` (they're currently three separate stylesheets, not one shared source of truth — see [TODO](#-known-quirks--todo)).
- **Monitors:** `hyprctl monitors` to get real output names, then edit `.config/hypr/modules/monitors.lua`. Workspace‑to‑monitor pinning happens via `hl.workspace_rule`.
- **Keybinds / default apps:** `terminal`, `fileManager` and `menu` are set as local variables at the top of `.config/hypr/modules/binds.lua` — change those three lines to swap apps globally.
- **Animations:** curves and per‑element speeds live in `.config/hypr/modules/decorations.lua` (`hl.curve` / `hl.animation`).
- **Wallpapers:** drop images into `.config/quickshell/hyprquickpaper/Wallpapers/` and adjust `number_of_pictures` / `cache_batch_size` in that folder's `config.json`.
- **Waybar modules:** `.config/waybar/config.jsonc` — current layout is `clock, pulseaudio` (left) / `network, workspaces, memory` (center) / `notification, battery, cava` (right).
- **Notification center buttons:** the quick‑toggle grid (Wi‑Fi, Bluetooth, Sound, Sleep) is defined in `.config/swaync/config.json` under `widget-config.buttons-grid.actions`.
- **fastfetch logo:** swap `logo.source` in `.config/fastfetch/config.jsonc` between `ascii/anime_small.txt` and `ascii/anime_square.txt`, or drop in your own ASCII art.
- **GTK theme:** re‑run `nwg-look` and re‑select the values in [`GTK-SETTINGS.md`](GTK-SETTINGS.md), or hand‑edit `~/.config/gtk-3.0/settings.ini` / `~/.config/gtk-4.0/settings.ini`.

---

## ⚠️ Known quirks / TODO

- `install.sh` handles packages + `.config` symlinks but deliberately skips system-level steps (swaync build, greetd, GRUB/Plymouth) — still manual, on purpose.
- `quickshell/hyprquickpaper/config.json` had my username (`san`) hardcoded into the wallpaper path — `install.sh` fixes this automatically now (step 3 below covers the manual equivalent).
- This repo and [`my_requie`](https://github.com/santa67creator/my_requie) (zsh/vim/starship) are two separate repos that happen to make up one machine's setup — worth merging into a single monorepo eventually instead of cloning both separately.
- `swaync`'s custom widgets require building swaync from source; there's no `meson.build`/build script committed for the patch itself.
- `awww-daemon` in `autostart.lua` doesn't match a package name I could verify — likely meant to be a wallpaper daemon like `swww`; confirm before relying on autostart.
- Colors are duplicated by value across Waybar/swaync/wlogout CSS instead of a single shared palette file/`@import`.
- `hyprlock.conf` is still close to the stock sample config — styling it to match the rest of the palette is still open.
- Monitor outputs (`eDP-1` / `HDMI-A-1`) and NVIDIA env vars are specific to my laptop (Acer Nitro AN515‑44, dual‑GPU) — non‑NVIDIA / different‑output users need to edit `env.lua` and `monitors.lua`.

---

## 📄 License

No license file is currently included in this repository — treat it as personal dotfiles shared for reference (all rights reserved by default) until a `LICENSE` file says otherwise. Feel free to fork and adapt individual configs; a permissive license (MIT) may be added later.
