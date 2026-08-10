#!/bin/sh
# Wallpaper follows power source: animated video on AC, static frame on battery.
# Wallpapers come from the active theme (~/.config/sway-themes/current).
# Called from waybar's battery.sh every 5s and once at sway startup; only acts
# when the AC state actually changed. `sway-theme` clears the state file to
# force a re-apply after switching themes.
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-power.state"
THEME_DIR="$HOME/.config/sway-themes/current"
video="$THEME_DIR/wallpaper.mp4"
still="$THEME_DIR/wallpaper-still.png"

acdev=""; for d in /sys/class/power_supply/AC /sys/class/power_supply/ADP* /sys/class/power_supply/ACAD*; do [ -e "$d" ] && acdev=$d && break; done
ac=$(cat "$acdev/online" 2>/dev/null || echo 1)   # no adapter device → assume AC (desktop)
prev=$(cat "$STATE_FILE" 2>/dev/null)
[ "$ac" = "$prev" ] && exit 0
echo "$ac" > "$STATE_FILE"

if [ "$ac" = "1" ] && [ -f "$video" ]; then
    pkill -x swaybg
    pgrep -x mpvpaper >/dev/null || \
        "$HOME/.local/bin/mpvpaper" -f -p -o 'no-audio loop hwdec=vaapi profile=fast panscan=1.0' '*' \
        "$video"
else
    pkill -x mpvpaper
    pgrep -x swaybg >/dev/null || \
        setsid -f swaybg -i "$still" -m fill
fi
