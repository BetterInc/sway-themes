#!/bin/sh
# sway-themes installer - Debian/Ubuntu.
# Installs apt dependencies, backs up existing configs, symlinks everything
# from this repo into ~/.config, and activates the default theme (matrix).
set -e

# If anything fails halfway: nothing is applied to your running session until
# sway reloads, backups are never deleted, and this script is idempotent.
trap 's=$?; [ $s -ne 0 ] && {
    echo ""
    echo "!! install failed (exit $s) - your running desktop is NOT affected"
    echo "   (changes only apply on the next sway reload/login)."
    echo "   Fix the issue and re-run ./install.sh - it is safe to re-run and"
    echo "   will simply complete the remaining steps (backups are kept)."
    echo "   Or roll everything back with ./uninstall.sh."
}' EXIT

REPO=$(dirname "$(realpath "$0")")
CONF="$HOME/.config"
DEFAULT_THEME=matrix

echo "==> sway-themes installer (repo: $REPO)"

# ------------------------------------------------------------ dependencies
# Platform-generic: the rice itself is just symlinks in $HOME. Packaged
# dependencies are installed via whichever package manager exists; anything
# your distro doesn't package is built from source by build-from-source.sh.
# Installed via a distro package (e.g. /usr/share/sway-themes)? Then all
# dependencies and binaries are the package manager's job - this script only
# needs to do the per-user symlinking below.
case "$REPO" in /usr/*) SWAY_THEMES_NO_DEPS=1; SWAY_THEMES_NO_BUILD=1 ;; esac

SUDO=""; [ "$(id -u)" != 0 ] && SUDO=sudo
echo "==> Installing packaged dependencies (sudo required)"
if [ -n "$SWAY_THEMES_NO_DEPS" ]; then
    echo "    (skipped: packaged install, dependencies handled by the package)"
elif command -v apt-get >/dev/null; then
    $SUDO apt-get install -y waybar foot rofi swaybg swayidle dunst ffmpeg \
        fonts-font-awesome
elif command -v pacman >/dev/null; then
    rofi_pkg=rofi; pacman -Si rofi-wayland >/dev/null 2>&1 && rofi_pkg=rofi-wayland
    $SUDO pacman -S --needed --noconfirm waybar foot "$rofi_pkg" swaybg swayidle \
        dunst ffmpeg otf-font-awesome ttf-jetbrains-mono-nerd
elif command -v dnf >/dev/null; then
    $SUDO dnf install -y waybar foot rofi-wayland swaybg swayidle dunst ffmpeg \
        fontawesome-fonts
else
    echo "!! unknown package manager - install these yourself, then re-run:"
    echo "   waybar foot rofi(-wayland) swaybg swayidle dunst ffmpeg font-awesome"
fi

# SwayFX (required: the whole look depends on rounded corners/blur/shadows),
# swaylock-effects and mpvpaper are rarely packaged. Prefer an AUR helper if
# one exists; otherwise build-from-source.sh builds them into ~/.local.
need_build=""
sway --version 2>/dev/null | grep -q '^sway version 0\.3' || need_build="swayfx"
command -v swaylock >/dev/null || need_build="$need_build swaylock-effects"
command -v mpvpaper >/dev/null || need_build="$need_build mpvpaper"
[ -n "$SWAY_THEMES_NO_BUILD" ] && need_build=""   # CI/boot-test: configs only
if [ -n "$need_build" ]; then
    aur=""
    for h in paru yay; do command -v "$h" >/dev/null && aur=$h && break; done
    if [ -n "$aur" ]; then
        echo "==> Installing missing components from the AUR:$need_build"
        "$aur" -S --needed swayfx swaylock-effects-git mpvpaper
    else
        echo "==> Building missing components from source:$need_build"
        "$REPO/build-from-source.sh"
    fi
fi
fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd' || echo "!! JetBrainsMono Nerd Font not installed - https://github.com/ryanoasis/nerd-fonts, unzip into ~/.local/share/fonts, run fc-cache -f"

# ------------------------------------------------------------- symlink helper
link() { # link <target> <linkpath>
    mkdir -p "$(dirname "$2")"
    if [ -e "$2" ] && [ ! -L "$2" ]; then
        echo "   backing up $2 -> $2.bak"
        mv "$2" "$2.bak"
    fi
    ln -sfn "$1" "$2"
    echo "   $2 -> $1"
}

echo "==> Linking configs into ~/.config"
# sway
link "$REPO/config/sway/config"           "$CONF/sway/config"
link "$REPO/config/sway/scripts"          "$CONF/sway/scripts"
link "$REPO/config/sway/set_env_vars.sh"  "$CONF/sway/set_env_vars.sh"
link "$REPO/config/sway/status.sh"        "$CONF/sway/status.sh"
# waybar (colors.css points into the active theme)
link "$REPO/config/waybar/config"         "$CONF/waybar/config"
link "$REPO/config/waybar/style.css"      "$CONF/waybar/style.css"
link "$REPO/config/waybar/battery.sh"     "$CONF/waybar/battery.sh"
link "../sway-themes/current/waybar-colors.css" "$CONF/waybar/colors.css"
# foot
link "$REPO/config/foot/foot.ini"         "$CONF/foot/foot.ini"
link "../sway-themes/current/foot-colors.ini"   "$CONF/foot/theme.ini"
# rofi
link "$REPO/config/rofi/config.rasi"      "$CONF/rofi/config.rasi"
link "../sway-themes/current/rofi.rasi"         "$CONF/rofi/theme.rasi"
# swaylock
link "../sway-themes/current/swaylock.config"   "$CONF/swaylock/config"
# dunst (notifications - whole config is per-theme, dunst <1.10 has no includes)
link "../sway-themes/current/dunstrc"           "$CONF/dunst/dunstrc"
# theme switcher on PATH
link "$REPO/bin/sway-theme"               "$HOME/.local/bin/sway-theme"

# ------------------------------------------------------------- default theme
mkdir -p "$CONF/sway-themes/themes"   # drop your own themes here
if [ ! -e "$CONF/sway-themes/current" ]; then
    ln -sfn "$REPO/themes/$DEFAULT_THEME" "$CONF/sway-themes/current"
    echo "==> Activated default theme: $DEFAULT_THEME"
fi

chmod +x "$REPO"/bin/* "$REPO"/config/sway/scripts/*.sh "$REPO"/config/waybar/battery.sh 2>/dev/null || true

echo "==> Done. Switch themes with:  sway-theme <name>   (list: sway-theme)"
echo "    Apply now with:  swaymsg reload   (or Mod+Shift+c) - reloads sway,"
echo "    waybar, wallpaper, rofi and swaylock in place. Only replacing the"
echo "    compositor binary itself (installing/upgrading swayfx) needs a re-login."
