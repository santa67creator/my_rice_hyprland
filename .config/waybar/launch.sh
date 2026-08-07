#!/bin/bash

pkill waybar
pkill swaync

swaync &
waybar &