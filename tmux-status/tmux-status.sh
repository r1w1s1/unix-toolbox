#!/usr/bin/env sh
#
# Copyright 2025  r1w1s1
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Minimal tmux/X11 status script
#
# Properties:
#   - POSIX sh
#   - No daemons
#   - No config files
#   - Reads directly from /sys
#   - X11 features auto-disable when unavailable

cpu() {
    command -v vmstat >/dev/null 2>&1 || return

    vmstat 1 2 | awk 'END { printf "CPU:%d%%", 100 - $15 }'
}

mem() {
    command -v free >/dev/null 2>&1 || return
 
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
    command -v xprop >/dev/null 2>&1 || return

    cur=$(xprop -root _NET_CURRENT_DESKTOP 2>/dev/null | awk '{print $NF}')
    [ -n "$cur" ] && printf "WS:%d" "$((cur + 1))"
}

date_str() {
    date '+%Y-%m-%d %H:%M'
}

printf "%s | %s | %s | %s | %s\n" \
    "$(cpu)" \
    "$(mem)" \
    "$(bat)" \
    "$(ws)" \
    "$(date_str)"

