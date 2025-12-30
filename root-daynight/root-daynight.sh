#!/usr/bin/env bash
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
# Simple day/night root background and wallpaper switcher (X11 only)
#
# Design:
# - Solid color is always applied (primary)
# - Wallpaper is optional and applied on top (secondary)
#

# ---------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------

DAY_COLOR="#c6ccd6"
NIGHT_COLOR="#24272d"

# Leave empty ("") to disable wallpapers
DAY_WALLPAPER=""
NIGHT_WALLPAPER=""

DAY_START=7     # 07:00
NIGHT_START=19  # 19:00

SLEEP_TIME=300  # seconds

# ---------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------

command -v xsetroot >/dev/null 2>&1 || {
    echo "root-daynight: xsetroot not found" >&2
    exit 1
}

# feh is only required if wallpapers are used
if [ -n "$DAY_WALLPAPER" ] || [ -n "$NIGHT_WALLPAPER" ]; then
    command -v feh >/dev/null 2>&1 || {
        echo "root-daynight: feh not found (required for wallpaper support)" >&2
        exit 1
    }
fi

# ---------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------

STATE=""

while :; do
    HOUR=$(date +%H)

    if [ "$HOUR" -ge "$NIGHT_START" ] || [ "$HOUR" -lt "$DAY_START" ]; then
        NEW_STATE="night"
        COLOR="$NIGHT_COLOR"
        WALLPAPER="$NIGHT_WALLPAPER"
    else
        NEW_STATE="day"
        COLOR="$DAY_COLOR"
        WALLPAPER="$DAY_WALLPAPER"
    fi

    if [ "$NEW_STATE" != "$STATE" ]; then
        # Always set base root color
        xsetroot -solid "$COLOR"

        # Optional wallpaper overlay
        if [ -n "$WALLPAPER" ]; then
            feh --no-fehbg --bg-scale "$WALLPAPER"
        fi

        STATE="$NEW_STATE"
    fi

    sleep "$SLEEP_TIME"
done

