#!/bin/sh
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
# root-daynight.sh
#
# Simple time-based root background policy for X11.
#
# Design principles:
# - Always set a solid root color (primary, fast, no dependencies)
# - Optional wallpaper overlay (secondary, via hsetroot)
# - Sleeps exactly until the next transition instead of polling,
#   waking only twice a day (at DAY_START and NIGHT_START)
# - Corrects itself on startup if the machine was off at transition time
# - Safe to call from xinitrc (will not duplicate)
#

# ---------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------
DAY_COLOR="#c6ccd6"
NIGHT_COLOR="#24272d"
# Leave empty ("") to disable wallpapers
DAY_WALLPAPER=""
NIGHT_WALLPAPER=""
DAY_START=9     # 09:00
NIGHT_START=19  # 19:00

# ---------------------------------------------------------------------
# Internal state / locking
# ---------------------------------------------------------------------
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/root-daynight.pid"
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        exit 0
    fi
fi
echo $$ > "$PIDFILE"
cleanup() {
    rm -f "$PIDFILE"
    exit 0
}
trap cleanup INT TERM EXIT

# ---------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------
command -v xsetroot >/dev/null 2>&1 || {
    echo "root-daynight: xsetroot not found" >&2
    exit 1
}
if [ -n "$DAY_WALLPAPER" ] || [ -n "$NIGHT_WALLPAPER" ]; then
    command -v hsetroot >/dev/null 2>&1 || {
        echo "root-daynight: hsetroot not found (required for wallpaper support)" >&2
        exit 1
    }
fi

# ---------------------------------------------------------------------
# Validate wallpaper files
# ---------------------------------------------------------------------
if [ -n "$DAY_WALLPAPER" ] && [ ! -f "$DAY_WALLPAPER" ]; then
    echo "root-daynight: Warning: DAY_WALLPAPER not found: $DAY_WALLPAPER" >&2
    DAY_WALLPAPER=""
fi
if [ -n "$NIGHT_WALLPAPER" ] && [ ! -f "$NIGHT_WALLPAPER" ]; then
    echo "root-daynight: Warning: NIGHT_WALLPAPER not found: $NIGHT_WALLPAPER" >&2
    NIGHT_WALLPAPER=""
fi

# ---------------------------------------------------------------------
# Helper: seconds until HH:00:00 today, or tomorrow if already past
# ---------------------------------------------------------------------
seconds_until() {
    TARGET_H=$1
    NOW=$(date +%s)
    TODAY=$(date +%Y-%m-%d)
    TARGET=$(date -d "$TODAY $TARGET_H:00:00" +%s)
    [ "$TARGET" -le "$NOW" ] && TARGET=$((TARGET + 86400))
    echo $((TARGET - NOW))
}

# ---------------------------------------------------------------------
# Main loop — wakes only at each transition, not on a fixed poll interval
# ---------------------------------------------------------------------
while :; do
    HOUR=$(date +%H)
    HOUR=${HOUR#0}
    [ -z "$HOUR" ] && HOUR=0

    if [ "$HOUR" -ge "$NIGHT_START" ] || [ "$HOUR" -lt "$DAY_START" ]; then
        COLOR="$NIGHT_COLOR"
        WALLPAPER="$NIGHT_WALLPAPER"
        SLEEP=$(seconds_until "$DAY_START")
    else
        COLOR="$DAY_COLOR"
        WALLPAPER="$DAY_WALLPAPER"
        SLEEP=$(seconds_until "$NIGHT_START")
    fi

    xsetroot -solid "$COLOR"
    if [ -n "$WALLPAPER" ]; then
        hsetroot -fill "$WALLPAPER"
    fi

    sleep "$SLEEP"
done
