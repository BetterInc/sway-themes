# sway-themes

[![ci](https://github.com/BetterInc/sway-themes/actions/workflows/ci.yml/badge.svg)](https://github.com/BetterInc/sway-themes/actions/workflows/ci.yml)

A themeable SwayFX rice. One command switches the whole desktop - window
borders, waybar, foot (including already-open terminals), rofi, swaylock,
dunst notifications and the animated wallpaper.

| matrix | purple |
|---|---|
| ![matrix](docs/matrix.png) | ![purple](docs/purple.png) |

## Quick start

**Debian 12 / Ubuntu 24.04 (amd64)** - prebuilt packages, including a
compiled SwayFX:

```sh
sudo install -d /etc/apt/keyrings
curl -fsSL https://betterinc.github.io/sway-themes/apt/public.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/sway-themes.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/sway-themes.gpg] https://betterinc.github.io/sway-themes/apt stable main" | \
  sudo tee /etc/apt/sources.list.d/sway-themes.list

sudo apt update && sudo apt install sway-themes   # pulls swayfx & everything else
sway-themes-setup                                 # activate for your user
```

**Any other distro** - clone and build (Arch, Fedora and unknown package
managers are handled):

```sh
git clone https://github.com/BetterInc/sway-themes ~/sway-themes
~/sway-themes/install.sh
```

Then log in to sway. Existing configs are backed up as `*.bak`;
`uninstall.sh` (or `/usr/share/sway-themes/uninstall.sh`) restores them.

> `swayfx` ships `/usr/bin/sway` and replaces the stock `sway` package;
> `swaylock-effects` replaces `swaylock`.

## Switch themes

```sh
sway-theme            # list (* = active)
sway-theme purple     # switch everything, live
```

No re-login needed: borders, waybar, wallpaper, rofi, swaylock and dunst
update immediately, and open foot terminals are recolored in place (the
switcher pushes OSC 4/10/11/12 palette escapes to your PTYs, pywal-style).
Only upgrading the swayfx binary itself ever needs a re-login.

## Make your own theme

Setup already created a starter theme owned by you, no root needed:

```
~/.config/sway-themes/themes/example
```

It is a complete theme with its own teal palette - every file is plain text
(sway colors, waybar palette, foot terminal colors, rofi, swaylock, dunst)
plus a generated animated-gradient wallpaper. Edit anything in it and run
`sway-theme example` to see your changes.

Making a new theme is literally one copy - duplicate the example (or any
theme) under a new name in the same directory:

```sh
cp -r ~/.config/sway-themes/themes/example ~/.config/sway-themes/themes/mytheme
$EDITOR ~/.config/sway-themes/themes/mytheme/*   # change the colors
sway-theme mytheme
```

Everything under `~/.config/sway-themes/themes/` is yours: it never needs
sudo, survives apt upgrades, and wins over shipped themes on name conflicts.
No rebuild, no reload commands to remember - `sway-theme <name>` applies it
live.

A theme is just a directory of color files - each optional:
`sway-colors.conf`, `waybar-colors.css`, `foot-colors.ini`, `rofi.rasi`,
`swaylock.config`, `dunstrc`, `wallpaper.mp4`, `wallpaper-still.png`.
PRs with new themes are welcome.

## Wallpapers

Animated wallpapers play on AC power (mpvpaper) and drop to a still image
on battery (swaybg). The `.mp4` files are not committed - download free
from Pixabay into the theme directory:

| theme | video (Pixabay Content License) | save as |
|---|---|---|
| matrix | [green digital rain, 4K 30s](https://pixabay.com/videos/matrix-computer-network-47802/) | `~/.config/sway-themes/wallpapers/matrix.mp4` |
| purple | [dark plexus constellation](https://pixabay.com/videos/plexus-abstract-background-colorful-57860/) | `~/.config/sway-themes/wallpapers/purple.mp4` |

Save location - either works, the user directory wins if both exist:

- `~/.config/sway-themes/wallpapers/<theme>.mp4` - per user, no root needed
- `<theme dir>/wallpaper.mp4` - system-wide; for apt installs that is
  `/usr/share/sway-themes/themes/<theme>/wallpaper.mp4` (needs sudo, and
  dpkg leaves manually added files alone on upgrades)

No video? The theme just uses its committed still full-time. Any loop you
like works - tip: `ffmpeg -i in.mp4 -vf hue=h=200 -an out.mp4` recolors one.

## How it works

Structure and colors are separated. `config/` holds theme-agnostic configs
for sway, waybar, foot and rofi; each `themes/<name>/` is a self-contained
color + wallpaper pack. One symlink - `~/.config/sway-themes/current` -
selects the active theme, and every app config reads its colors through it.

```
bin/sway-theme       theme switcher CLI
install.sh           deps (apt/pacman/dnf) + symlinks into ~/.config
uninstall.sh         removes symlinks, restores *.bak backups
build-from-source.sh SwayFX 0.3.2 (static wlroots 0.16.2), swaylock-effects, mpvpaper
packaging/mkdebs.sh  builds the .deb packages published to the APT repo
config/              sway, waybar, foot, rofi + wallpaper/battery scripts
themes/matrix        green rain
themes/purple        neon violet
```

Setup puts the app configs (sway keybindings, waybar layout, foot, rofi) in
`~/.config` as normal files you own and edit - no sudo, and re-running setup
never overwrites a file you changed. Only the theme machinery is symlinked
(the `current` pointer and per-app color includes), which is what makes
`sway-theme` switches instant. Nothing outside `~/.config` and
`~/.local/bin` is touched. CI installs the full rice on Debian 12, Ubuntu
24.04, Arch and Fedora, boots it headless and screenshots it (see the
Actions artifacts).

## Requirements (source install only)

The apt packages handle all of this. `install.sh` installs runtime deps via
apt/pacman/dnf and runs `build-from-source.sh` for the rest:

| built from source | why |
|---|---|
| [SwayFX](https://github.com/WillPower3309/swayfx) 0.3.2 | **required** - rounded corners, blur, shadows are the look. Static wlroots 0.16.2 (Debian 12 ships 0.15). |
| [swaylock-effects](https://github.com/jirutka/swaylock-effects) | themed lock screen (blurred screenshot + clock) |
| [mpvpaper](https://github.com/GhostNaN/mpvpaper) | optional - animated wallpaper |

Font: [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts) ->
`~/.local/share/fonts`, then `fc-cache -f`.
