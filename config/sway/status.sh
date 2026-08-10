#!/bin/sh
while true; do
    cap=$(cat /sys/class/power_supply/BAT0/capacity)
    ac=$(cat /sys/class/power_supply/AC/online)
    if [ "$ac" = "1" ]; then
        icon="⚡"
    elif [ "$cap" -le 15 ]; then
        icon="🪫"
    else
        icon="🔋"
    fi
    echo "$icon ${cap}%  |  $(date +'%Y-%m-%d %I:%M:%S %p')"
    sleep 1
done
