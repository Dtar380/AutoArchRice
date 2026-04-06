#!/bin/bash
# =============================================================================
#  Rice Autostart
#  Launches rice services on Hyprland startup
# =============================================================================

# Wait for Hyprland to be fully ready
sleep 2

# Start workspace guard
if command -v rice-workspace-guard &>/dev/null; then
    rice-workspace-guard start
fi

# Additional startup services can go here
# Example:
# rice-theme-apply  # Apply saved theme
# rice-wallpaper-apply  # Set saved wallpaper
