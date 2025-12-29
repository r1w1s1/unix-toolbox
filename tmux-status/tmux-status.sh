#!/bin/sh
#
# Minimal status script
# CPU usage, memory usage, and correct multi-battery status
#
# Designed for:
#   - tmux status line
#   - dwm / pekwm / panel-less setups
#
# Properties:
#   - POSIX sh
#   - No daemons
#   - No config files
#   - Reads directly from /sys
#   - Correct ThinkPad multi-battery handling
#

cpu() {
    vmstat 1 2 | awk 'END { printf "CPU:%d%%", 100 - $15 }'
}

mem() {
    free -h | awk '/^Mem:/ { printf "MEM:%s/%s", $3, $2 }'
}

bat() {
    total_now=0
    total_full=0
    charging=0
    full=1

    for b in /sys/class/power_supply/BAT*; do
        [ -d "$b" ] || continue

        if [ -f "$b/energy_now" ]; then
            now=$(cat "$b/energy_now")
            full_cap=$(cat "$b/energy_full")
        else
            now=$(cat "$b/charge_now")
            full_cap=$(cat "$b/charge_full")
        fi

        status=$(cat "$b/status")

        total_now=$((total_now + now))
        total_full=$((total_full + full_cap))

        [ "$status" = "Charging" ] && charging=1
        [ "$status" != "Full" ] && full=0
    done

    [ "$total_full" -eq 0 ] && return

    percent=$((100 * total_now / total_full))

    if [ "$charging" -eq 1 ]; then
        state="+"
    elif [ "$full" -eq 1 ]; then
        state="="
    else
        state="-"
    fi

    printf "BAT:%d%%%s" "$percent" "$state"
}

ws() {
    [ -z "$DISPLAY" ] && return
    cur=$(xprop -root _NET_CURRENT_DESKTOP 2>/dev/null | awk '{print $NF}')
    [ -n "$cur" ] && printf "WS:%d" "$((cur + 1))"
}

date_str() {
    date '+%Y-%m-%d %H:%M'
}

printf "%s | %s | %s | %s | %s\n" "$(cpu)" "$(mem)" "$(bat)" "$(ws)" "$(date_str)"

