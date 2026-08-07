# GTK Settings

GTK theming configuration managed via [`nwg-look`](https://github.com/nwg-piotr/nwg-look) `v1.1.1` (Hyprland / wlroots).

## Widgets

| Setting        | Value                    |
|----------------|--------------------------|
| GTK theme      | `Gruvbox-Material-Dark`  |
| Default font   | Rubik Bold, 11.3         |
| Color scheme   | Prefer dark              |

## Icon Theme

| Setting     | Value      |
|-------------|------------|
| Icon theme  | `Papirus`  |

## Mouse Cursor

| Setting       | Value                    |
|---------------|--------------------------|
| Cursor theme  | `Bibata-Modern-Amber`    |
| Cursor size   | 24 (default: 24)         |

## Font Rendering

| Setting             | Value   |
|---------------------|---------|
| Font hinting        | Slight  |
| Font antialiasing   | rgba    |
| Font RGBA order     | RGB     |
| Text scaling factor | 0.95    |

---

## Applying these settings

`nwg-look` writes to the standard GTK config locations, so these settings can be restored on a fresh setup either by reopening `nwg-look` and re-selecting the same options, or by dropping the relevant config files into place:

- `~/.config/gtk-3.0/settings.ini`
- `~/.config/gtk-4.0/settings.ini`
- `~/.gtkrc-2.0`
- `~/.config/nwg-look/config` — save/restore whole nwg-look profile (theme, icons, cursor, font)
- `~/.icons/default/index.theme` — cursor theme symlink/config

Relevant `settings.ini` snippet for reference:

```ini
[Settings]
gtk-theme-name=Gruvbox-Material-Dark
gtk-icon-theme-name=Papirus
gtk-cursor-theme-name=Bibata-Modern-Amber
gtk-cursor-theme-size=24
gtk-font-name=Rubik Bold 11.3
gtk-application-prefer-dark-theme=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-antialias=1
gtk-xft-rgba=rgb
```

> Note: `Text scaling factor` (0.95) is an Xsettings/Wayland-specific value set by nwg-look and isn't part of the standard `settings.ini` — it's stored in nwg-look's own config and applied via `gsettings`/`xsettingsd` depending on your session.
