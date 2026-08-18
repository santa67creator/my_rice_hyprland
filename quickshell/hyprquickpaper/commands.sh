#!/usr/bin/env bash

WALLPAPER="$1"

awww img "$WALLPAPER" \
    --transition-type random \
    --transition-duration 1
