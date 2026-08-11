#!/bin/sh
# Fade unfocused windows so the wallpaper shows through; focused stays solid.
# Sleeps on sway's IPC socket - only wakes on window events.
INACTIVE=0.85

# Only one instance (sway reload re-runs exec_always)
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/inactive-opacity.lock"
flock -n 9 || exit 0

apply() {
    swaymsg "[app_id=\".*\"] opacity $INACTIVE; [class=\".*\"] opacity $INACTIVE; [con_id=__focused__] opacity 1" >/dev/null 2>&1
}

apply
swaymsg -t subscribe -m '["window"]' | while read -r event; do
    case "$event" in
        *'"change": "focus"'*|*'"change":"focus"'*|*'"change": "new"'*|*'"change":"new"'*) apply ;;
    esac
done
