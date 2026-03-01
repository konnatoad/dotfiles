#!/bin/sh

# start hyprpaper
hyprpaper &

# wait a moment for IPC to be ready
sleep 0.3

# set wallpaper via IPC (this is the part that WORKS)
hyprctl hyprpaper preload /home/konna/Pictures/cats_twilight_fixed.png
hyprctl hyprpaper wallpaper ",/home/konna/Pictures/cats_twilight_fixed.png"
