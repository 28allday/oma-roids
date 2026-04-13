# OMA-ROIDS

A classic Asteroids arcade game built with Love2D for [Omarchy](https://omarchy.org/) Linux.

Vector wireframe aesthetic that auto-detects your Omarchy system theme and font — the game matches your desktop.

[![OMA-ROIDS Gameplay](https://img.youtube.com/vi/_gYyesDgFtU/maxresdefault.jpg)](https://youtu.be/_gYyesDgFtU)

## Install

```bash
curl -sL https://git.no-signal.uk/nosignal/oma-roids/raw/branch/master/install.sh | bash
```

This will:
- Install Love2D if not present
- Clone the game to `~/.local/share/oma-roids/`
- Add an icon and launcher entry to your app menu
- Refresh the app launcher

Search **OMA-ROIDS** in your app launcher to play.

## Uninstall

```bash
oma-roids-uninstall
```

## Controls

| Key | Action |
|-----|--------|
| **Left / Right** or **A / D** | Rotate ship |
| **Up** or **W** | Thrust |
| **Space** | Fire (max 4 bullets) |
| **Shift** | Hyperspace (random teleport, 25% death risk) |
| **Enter** | Start game |
| **Escape** | Quit |

## Gameplay

- Destroy asteroids — large ones split into medium, medium into small
- Dodge and shoot UFO saucers for bonus points
- Screen wraps for ship and asteroids, bullets expire at edges
- Extra life every 10,000 points
- Persistent high scores with 3-letter initial entry

## Scoring

| Target | Points |
|--------|--------|
| Large asteroid | 20 |
| Medium asteroid | 50 |
| Small asteroid | 100 |
| Large saucer | 200 |
| Small saucer | 1,000 |

## Omarchy Integration

- **Theme colours** auto-detected from your active Omarchy theme
- **System font** detected from your Waybar config
- **Full-screen** via SUPER+F (Hyprland compositor)
- Switch themes with `omarchy-theme-set` and relaunch — the game adapts

## Requirements

- [Omarchy](https://omarchy.org/) Linux (or any Arch with Love2D)
- Love2D (`sudo pacman -S love`)

## Run from source

```bash
git clone https://git.no-signal.uk/nosignal/oma-roids.git
cd oma-roids
love .
```

## License

MIT
