#!/bin/sh
# Battery status for waybar - detects plugged state via the AC adapter,
# because batteries often report "Not charging" when plugged in near full.
# Device names vary per machine (BAT0/BAT1, AC/ADP1/ACAD), so probe for them.
bat=""; for d in /sys/class/power_supply/BAT*; do [ -e "$d" ] && bat=$d && break; done
acdev=""; for d in /sys/class/power_supply/AC /sys/class/power_supply/ADP* /sys/class/power_supply/ACAD*; do [ -e "$d" ] && acdev=$d && break; done

cap=$(cat "$bat/capacity" 2>/dev/null || echo 100)
ac=$(cat "$acdev/online" 2>/dev/null || echo 1)   # no adapter device -> assume AC (desktop)

if [ "$ac" = "1" ]; then
    text="⚡ ${cap}%"; class="plugged"; state="plugged in"
elif [ "$cap" -le 15 ]; then
    text="🪫 ${cap}%"; class="critical"; state="on battery - LOW"
elif [ "$cap" -le 30 ]; then
    text="🔋 ${cap}%"; class="warning"; state="on battery"
else
    text="🔋 ${cap}%"; class="discharging"; state="on battery"
fi

printf '{"text":"%s","class":"%s","tooltip":"Battery %s%% (%s)"}\n' \
    "$text" "$class" "$cap" "$state"

# Piggyback: switch wallpaper (animated on AC / static on battery) on state change
"$HOME/.config/sway/scripts/wallpaper-power.sh" >/dev/null 2>&1 &
