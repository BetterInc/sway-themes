#!/bin/sh
# Battery status for waybar — detects plugged state via AC adapter,
# because BAT0 reports "Not charging" when plugged in near full charge.
cap=$(cat /sys/class/power_supply/BAT0/capacity)
ac=$(cat /sys/class/power_supply/AC/online)

if [ "$ac" = "1" ]; then
    text="⚡ ${cap}%"; class="plugged"; state="plugged in"
elif [ "$cap" -le 15 ]; then
    text="🪫 ${cap}%"; class="critical"; state="on battery — LOW"
elif [ "$cap" -le 30 ]; then
    text="🔋 ${cap}%"; class="warning"; state="on battery"
else
    text="🔋 ${cap}%"; class="discharging"; state="on battery"
fi

printf '{"text":"%s","class":"%s","tooltip":"Battery %s%% (%s)"}\n' \
    "$text" "$class" "$cap" "$state"

# Piggyback: switch wallpaper (animated on AC / static on battery) on state change
"$HOME/.config/sway/scripts/wallpaper-power.sh" >/dev/null 2>&1 &
