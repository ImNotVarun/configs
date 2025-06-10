#!/bin/bash

# Get the boot time of the system
BOOT_TIME=$(date -d "$(uptime -s)" +%s)
CURRENT_TIME=$(date +%s)

# Calculate elapsed seconds
ELAPSED_SECONDS=$((CURRENT_TIME - BOOT_TIME))

# Convert to HH:MM:SS format
ELAPSED_TIME=$(printf "%02d:%02d:%02d" $((ELAPSED_SECONDS/3600)) $((ELAPSED_SECONDS%3600/60)) $((ELAPSED_SECONDS%60)))

# Animation frames (clock icons)
FRAMES=("󱑊 " "󱑋 " "󱑌 " "󱑍 " "󱑎 " "󱑏 " "󱑐 " "󱑑 " "󱑒 " "󱑓 " "󱑔 " "󱑕 ")
FRAME_INDEX=$((ELAPSED_SECONDS % ${#FRAMES[@]}))

# Output JSON for Waybar
echo "{\"text\":\"${FRAMES[$FRAME_INDEX]} $ELAPSED_TIME\",\"tooltip\":\"Session duration: $ELAPSED_TIME\"}"