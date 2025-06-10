#!/bin/bash

# Get current power profile
get_profile() {
    current_profile=$(powerprofilesctl get)
    echo "$current_profile"
}

# Show the proper format for waybar
show_status() {
    profile=$(get_profile)

    case "$profile" in
        "balanced")
            echo '{"text": "BAL", "class": "balanced", "tooltip": "Balanced Mode"}'
            ;;
        "performance")
            echo '{"text": "PERF", "class": "performance", "tooltip": "Performance Mode"}'
            ;;
        "power-saver")
            echo '{"text": "POW", "class": "power-saver", "tooltip": "Power Saver Mode"}'
            ;;
        *)
            echo '{"text": "unk", "tooltip": "Unknown Power Mode"}'
            ;;
    esac
}

# Handle clicks to change the profile
handle_click() {
    current=$(get_profile)

    case "$current" in
        "balanced")
            powerprofilesctl set performance
            ;;
        "performance")
            powerprofilesctl set power-saver
            ;;
        "power-saver"|*)
            powerprofilesctl set balanced
            ;;
    esac
}

# Main execution
if [[ "$1" == "click" ]]; then
    handle_click
else
    show_status
fi
