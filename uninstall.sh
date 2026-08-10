#!/bin/sh
# sway-themes uninstaller — removes the symlinks install.sh created and
# restores any *.bak backups it made. Leaves the repo itself untouched.
set -e

CONF="$HOME/.config"

unlink_restore() { # unlink_restore <linkpath>
    if [ -L "$1" ]; then
        rm "$1"
        echo "   removed $1"
    fi
    if [ -e "$1.bak" ]; then
        mv "$1.bak" "$1"
        echo "   restored $1 (from $1.bak)"
    fi
}

echo "==> Removing sway-themes symlinks and restoring backups"
unlink_restore "$CONF/sway/config"
unlink_restore "$CONF/sway/scripts"
unlink_restore "$CONF/sway/set_env_vars.sh"
unlink_restore "$CONF/sway/status.sh"
unlink_restore "$CONF/waybar/config"
unlink_restore "$CONF/waybar/style.css"
unlink_restore "$CONF/waybar/battery.sh"
unlink_restore "$CONF/waybar/colors.css"
unlink_restore "$CONF/foot/foot.ini"
unlink_restore "$CONF/foot/theme.ini"
unlink_restore "$CONF/rofi/config.rasi"
unlink_restore "$CONF/rofi/theme.rasi"
unlink_restore "$CONF/swaylock/config"
unlink_restore "$CONF/dunst/dunstrc"
unlink_restore "$HOME/.local/bin/sway-theme"

# active-theme pointer (keep ~/.config/sway-themes/themes — user's own themes)
[ -L "$CONF/sway-themes/current" ] && rm "$CONF/sway-themes/current" && echo "   removed $CONF/sway-themes/current"

echo "==> Done. Reload sway (swaymsg reload) to go back to your old config."
