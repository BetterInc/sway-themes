# sway-themes

My SwayFX rice with switchable themes (Matrix green, neon purple, ...).

| matrix | purple |
|---|---|
| ![matrix](docs/matrix.png) | ![purple](docs/purple.png) |

Structure and colors are separated: `config/` holds the theme-agnostic configs
for sway, waybar, foot, rofi and the wallpaper scripts; each directory under
`themes/` is a self-contained color + wallpaper pack. A single symlink
(`~/.config/sway-themes/current`) selects the active theme, and every app
config pulls its colors through it.

```
├── bin/sway-theme          # theme switcher CLI
├── install.sh              # apt deps + symlinks ~/.config into this repo
├── config/
│   ├── sway/               # sway config + scripts (wallpaper-power, inactive-opacity)
│   ├── waybar/             # bar config, structural style.css (@import colors.css)
│   ├── foot/               # terminal structure (includes ~/.config/foot/theme.ini)
│   └── rofi/               # launcher config (@theme "theme")
└── themes/
    ├── matrix/             # green rain
    │   ├── sway-colors.conf     # window borders + swayfx shadow tint
    │   ├── waybar-colors.css    # @define-color palette
    │   ├── foot-colors.ini      # terminal 16 colors, cursor, alpha
    │   ├── rofi.rasi            # launcher theme
    │   ├── swaylock.config      # lock screen colors/effects
    │   ├── wallpaper.mp4        # animated (mpvpaper, used on AC power)
    │   └── wallpaper-still.png  # static (swaybg, used on battery)
    └── purple/             # same files, violet palette (wallpapers are the
                            # matrix ones hue-shifted +145° with ffmpeg)
```

## Install

```sh
git clone <this repo> ~/sway-themes
~/sway-themes/install.sh
```

The installer apt-installs waybar/foot/rofi/swaybg/swayidle, backs up any
existing configs to `*.bak`, symlinks everything into `~/.config`, and
activates the matrix theme. Custom-built components (swayfx, swaylock-effects,
mpvpaper, JetBrainsMono Nerd Font) are checked and reported with build notes —
see the comments in `install.sh`.

## Switch themes

```sh
sway-theme            # list themes, * marks the active one
sway-theme purple     # switch: updates the symlink, restarts wallpaper, reloads sway
```

Everything applies live, no re-login needed: waybar, window borders, wallpaper,
rofi and swaylock update immediately — and already-open foot terminals are
recolored in place too (the switcher pushes the palette as OSC 4/10/11/12
escape sequences to every PTY, pywal-style). A re-login is only ever needed
when the compositor binary itself changes (installing or upgrading swayfx) —
never for theme switches or config changes.

## Add your own theme (no fork needed)

`sway-theme` looks for themes in two places, so you can make your own without
touching this repo:

```
~/.config/sway-themes/themes/<name>    your themes (wins on name conflict)
<repo>/themes/<name>                   themes shipped with the repo
```

Start from an existing theme and recolor:

```sh
mkdir -p ~/.config/sway-themes/themes
cp -r ~/sway-themes/themes/matrix ~/.config/sway-themes/themes/mytheme
$EDITOR ~/.config/sway-themes/themes/mytheme/*
sway-theme mytheme
```

A theme is just a directory with these files (all optional except the colors
you actually use): `sway-colors.conf`, `waybar-colors.css`, `foot-colors.ini`,
`rofi.rasi`, `swaylock.config`, `dunstrc` (notifications), `wallpaper.mp4`,
`wallpaper-still.png`.
Themes you want to share can be PR'd into `themes/` here.

A theme without `wallpaper.mp4` falls back to the still image at all times.
Tip: recolor the matrix wallpapers with ffmpeg's hue filter, e.g.
`ffmpeg -i themes/matrix/wallpaper.mp4 -vf hue=h=200 -an out.mp4` for blue.

## Wallpaper behavior

`config/sway/scripts/wallpaper-power.sh` plays the animated wallpaper via
mpvpaper on AC power and swaps to the static PNG via swaybg on battery
(checked every 5s from waybar's battery module).
