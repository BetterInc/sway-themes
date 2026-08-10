# sway-themes

My SwayFX rice with switchable themes (Matrix green, neon purple, ...).

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
rofi and swaylock update immediately; open foot terminals keep their colors and
new ones use the new theme. A re-login is only ever needed when the compositor
binary itself changes (installing or upgrading swayfx) — never for theme
switches or config changes.

## Add a theme

Copy an existing theme dir and recolor:

```sh
cp -r themes/matrix themes/mytheme
$EDITOR themes/mytheme/*
sway-theme mytheme
```

A theme without `wallpaper.mp4` falls back to the still image at all times.
Tip: recolor the matrix wallpapers with ffmpeg's hue filter, e.g.
`ffmpeg -i themes/matrix/wallpaper.mp4 -vf hue=h=200 -an out.mp4` for blue.

## Wallpaper behavior

`config/sway/scripts/wallpaper-power.sh` plays the animated wallpaper via
mpvpaper on AC power and swaps to the static PNG via swaybg on battery
(checked every 5s from waybar's battery module).
