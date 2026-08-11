#!/bin/sh
# Wallpaper follows power source: animated video on AC, static frame on battery.
# Wallpapers come from the active theme (~/.config/sway-themes/current).
# Called from waybar's battery.sh every 5s and once at sway startup; only acts
# when the AC state changed or no wallpaper process is running (so it
# self-heals after re-login or a crashed swaybg/mpvpaper). `sway-theme`
# clears the state file to force a re-apply after switching themes.
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-power.state"
THEME_DIR="$HOME/.config/sway-themes/current"
video="$THEME_DIR/wallpaper.mp4"
still="$THEME_DIR/wallpaper-still.png"

# mpvpaper may live in ~/.local/bin (source build) or /usr/bin (deb)
MPVPAPER=$(command -v mpvpaper || echo "$HOME/.local/bin/mpvpaper")

running() {
    pgrep -u "$(id -u)" -x mpvpaper >/dev/null || pgrep -u "$(id -u)" -x swaybg >/dev/null
}

acdev=""; for d in /sys/class/power_supply/AC /sys/class/power_supply/ADP* /sys/class/power_supply/ACAD*; do [ -e "$d" ] && acdev=$d && break; done
ac=$(cat "$acdev/online" 2>/dev/null || echo 1)   # no adapter device -> assume AC (desktop)
prev=$(cat "$STATE_FILE" 2>/dev/null)
[ "$ac" = "$prev" ] && running && exit 0
echo "$ac" > "$STATE_FILE"

if [ "$ac" = "1" ] && [ -f "$video" ] && [ -x "$MPVPAPER" ]; then
    pkill -x swaybg
    pgrep -u "$(id -u)" -x mpvpaper >/dev/null || \
        "$MPVPAPER" -f -p -o 'no-audio loop hwdec=vaapi profile=fast panscan=1.0' '*' \
        "$video"
else
    pkill -x mpvpaper
    pgrep -u "$(id -u)" -x swaybg >/dev/null || \
        setsid -f swaybg -i "$still" -m fill
fi
