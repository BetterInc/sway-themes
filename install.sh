#!/bin/sh
# sway-themes installer — Debian/Ubuntu.
# Installs apt dependencies, backs up existing configs, symlinks everything
# from this repo into ~/.config, and activates the default theme (matrix).
set -e

# If anything fails halfway: nothing is applied to your running session until
# sway reloads, backups are never deleted, and this script is idempotent.
trap 's=$?; [ $s -ne 0 ] && {
    echo ""
    echo "!! install failed (exit $s) — your running desktop is NOT affected"
    echo "   (changes only apply on the next sway reload/login)."
    echo "   Fix the issue and re-run ./install.sh — it is safe to re-run and"
    echo "   will simply complete the remaining steps (backups are kept)."
    echo "   Or roll everything back with ./uninstall.sh."
}' EXIT

REPO=$(dirname "$(realpath "$0")")
CONF="$HOME/.config"
DEFAULT_THEME=matrix

echo "==> sway-themes installer (repo: $REPO)"

# ---------------------------------------------------------------- apt deps
if command -v apt >/dev/null; then
    echo "==> Installing apt dependencies (sudo required)"
    sudo apt install -y waybar foot rofi swaybg swayidle dunst ffmpeg \
        fonts-font-awesome
else
    echo "!! apt not found — install manually: waybar foot rofi swaybg swayidle"
fi

# Components NOT in the Debian repos — SwayFX (required: the whole look
# depends on rounded corners/blur/shadows), swaylock-effects and mpvpaper.
# build-from-source.sh builds whatever is missing into ~/.local.
need_build=""
sway --version 2>/dev/null | grep -q '^sway version 0\.3' || need_build="swayfx"
command -v swaylock >/dev/null || need_build="$need_build swaylock-effects"
command -v mpvpaper >/dev/null || need_build="$need_build mpvpaper"
if [ -n "$need_build" ]; then
    echo "==> Building missing components from source:$need_build"
    "$REPO/build-from-source.sh"
fi
fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd' || echo "!! JetBrainsMono Nerd Font not installed — https://github.com/ryanoasis/nerd-fonts, unzip into ~/.local/share/fonts, run fc-cache -f"

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
# dunst (notifications — whole config is per-theme, dunst <1.10 has no includes)
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
echo "    Apply now with:  swaymsg reload   (or Mod+Shift+c) — reloads sway,"
echo "    waybar, wallpaper, rofi and swaylock in place. Only replacing the"
echo "    compositor binary itself (installing/upgrading swayfx) needs a re-login."
