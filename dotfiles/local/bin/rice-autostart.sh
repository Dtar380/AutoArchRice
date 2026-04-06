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

# Apply saved theme on startup
if command -v rice-theme &>/dev/null; then
    RICE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/rice"
    if [[ -f "$RICE_DIR/state" ]]; then
        ACTIVE_THEME=$(sed -n '1p' "$RICE_DIR/state" 2>/dev/null)
        if [[ -n "$ACTIVE_THEME" ]] && [[ "$ACTIVE_THEME" != "none" ]]; then
            rice-theme set "$ACTIVE_THEME" >/dev/null 2>&1 || true
        fi
    fi
fi

# Additional startup services can go here
