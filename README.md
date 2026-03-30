# My-Stein

Frankenstein's monster Hyprland desktop config, built entirely in [Quickshell](https://quickshell.outfoxxed.me/) (QML). Combines ilyamiro's wallpaper selector and music widget with end4-inspired overview/app launcher, plus custom bars and notifications — all themed via matugen.

<!-- ![screenshot](screenshots/desktop.png) -->

## Features

- **Wallpaper Picker** (Super+W) — Browse local wallpapers + DDG image search, swww/mpvpaper support, color extraction filtering
- **Music Popup** (Super+M) — Player controls, progress seeking, 10-band EQ with presets (via EasyEffects)
- **Overview + App Launcher** (Super+Tab) — Workspace grid with window previews, type-to-search app launcher
- **Notification Popup** — Minimalistic notifications, auto-dismiss, max 3 stacked
- **TopBar** (DP-1) — Horizontal pill bar: workspace dots, gamemode indicator, clock, volume, music toggle
- **SideBar** (HDMI-A-1) — Vertical bar on right edge for secondary vertical monitor
- **Matugen Theming** — Material You colors generated from wallpaper, Catppuccin Mocha fallbacks

Optimized for gaming: no continuous animations, no blur, polling only when widgets are visible.

## Dependencies

### Required
| Package | Command | Purpose |
|---------|---------|---------|
| hyprland | `hyprctl` | Compositor |
| quickshell | `quickshell` | Shell framework |
| swww | `swww` | Wallpaper daemon |
| matugen | `matugen` | Color generation |
| playerctl | `playerctl` | Media control |
| pipewire-pulse | `pactl` | Volume control |
| jq | `jq` | JSON parsing |
| curl | `curl` | DDG wallpaper search |
| python3 | `python3` | DDG link extraction |

### Optional
| Package | Purpose |
|---------|---------|
| gamemode | Gaming mode indicator in bar |
| easyeffects | Parametric EQ (music popup) |
| mpvpaper | Video wallpaper support |
| imagemagick | Wallpaper thumbnails |
| cava | Audio visualizer |

### Fonts
- **JetBrains Mono Nerd Font** — UI text
- **Iosevka Nerd Font** — Icons

## Structure

```
.config/
├── quickshell/
│   ├── shell.qml                 # Entry point
│   ├── MatugenColors.qml         # Theme colors (matugen + fallbacks)
│   ├── MonitorConfig.qml         # Monitor names (edit for your setup)
│   ├── modules/
│   │   ├── bar/
│   │   │   ├── TopBar.qml        # Horizontal bar (DP-1)
│   │   │   └── SideBar.qml       # Vertical bar (HDMI-A-1)
│   │   ├── music/
│   │   │   ├── MusicPopup.qml    # Player + EQ popup
│   │   │   ├── music_info.sh
│   │   │   ├── player_control.sh
│   │   │   └── equalizer.sh
│   │   ├── notifications/
│   │   │   └── NotificationPopup.qml
│   │   ├── overview/
│   │   │   ├── Overview.qml      # Fullscreen overlay
│   │   │   ├── OverviewWidget.qml
│   │   │   ├── OverviewWindow.qml
│   │   │   ├── SearchBar.qml
│   │   │   ├── SearchWidget.qml
│   │   │   └── SearchItem.qml
│   │   └── wallpaper/
│   │       ├── WallpaperPicker.qml
│   │       ├── ddg_search.sh
│   │       ├── get_ddg_links.py
│   │       ├── debug_pipelines.sh
│   │       └── matugen_reload.sh
│   └── services/
│       └── HyprlandData.qml      # Hyprland IPC polling
├── hypr/
│   └── hyprland.conf             # Keybinds + exec-once
└── matugen/
    ├── config.toml
    └── templates/
        └── quickshell-colors.json
```

## Setup

1. Clone this repo
2. Symlink configs:
   ```bash
   ln -sf "$(pwd)/.config/quickshell" ~/.config/quickshell
   ln -sf "$(pwd)/.config/matugen" ~/.config/matugen
   ```
3. Add to your `~/.config/hypr/hyprland.conf`:
   ```
   source = /path/to/My-Stein/.config/hypr/hyprland.conf
   ```
4. Edit `MonitorConfig.qml` with your monitor names (check `hyprctl monitors`):
   ```qml
   readonly property string primaryMonitor: "DP-1"      // your main monitor
   readonly property string secondaryMonitor: "HDMI-A-1" // your secondary monitor
   ```
5. Add wallpapers to `~/Pictures/Wallpapers/`
6. Generate initial theme:
   ```bash
   matugen image ~/Pictures/Wallpapers/your-wallpaper.jpg
   ```
7. Start quickshell (or log out and back in):
   ```bash
   quickshell -p ~/.config/quickshell
   ```

## Keybinds

| Key | Action |
|-----|--------|
| Super+Tab | Overview / App Launcher |
| Super+W | Wallpaper Picker |
| Super+M | Music Popup |

## Credits

- [ilyamiro/nixos-configuration](https://github.com/ilyamiro/nixos-configuration) — Wallpaper picker, music widget
- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — Overview/launcher inspiration
- [Quickshell](https://quickshell.outfoxxed.me/) — Shell framework
- [matugen](https://github.com/InioX/matugen) — Material You color generation
