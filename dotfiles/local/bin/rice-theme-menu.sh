#!/bin/bash
# =============================================================================
#  Rice Theme & Wallpaper Menu
#  Rofi-based menu for theme/wallpaper selection with animations
# =============================================================================

set -euo pipefail

readonly RICE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/rice"
readonly THEME_DIR="$RICE_DIR/themes"

# Logging
_error() {
    echo "ERROR: $*" >&2
    exit 1
}

_info() {
    notify-send -t 2000 "Rice" "$*"
}

# =============================================================================
#  Menu Functions
# =============================================================================

show_theme_menu() {
    local themes
    mapfile -t themes < <(find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d | sed "s|$THEME_DIR/||" | sort)

    # Create menu string
    local menu_items=""
    for theme in "${themes[@]}"; do
        menu_items+="$theme\n"
    done

    # Show rofi menu
    echo -e "${menu_items%\\n}" | rofi -dmenu -p "Select Theme: " -lines "${#themes[@]}"
}

show_wallpaper_menu() {
    local theme=$1
    local wallpaper_dir="$THEME_DIR/$theme/wallpapers"

    if [[ ! -d "$wallpaper_dir" ]]; then
        _error "No wallpapers found for theme: $theme"
    fi

    # Get wallpapers
    local wallpapers
    mapfile -t wallpapers < <(find "$wallpaper_dir" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | sed "s|$wallpaper_dir/||" | sort)

    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        _error "No wallpapers found in: $wallpaper_dir"
    fi

    # Create menu string with preview
    local menu_items=""
    for wallpaper in "${wallpapers[@]}"; do
        menu_items+="$wallpaper\n"
    done

    # Show rofi menu
    echo -e "${menu_items%\\n}" | rofi -dmenu -p "Select Wallpaper: " -lines "${#wallpapers[@]}"
}

# =============================================================================
#  Main Menu Flow
# =============================================================================

main() {
    # Theme selection
    local selected_theme
    selected_theme=$(show_theme_menu)

    if [[ -z "$selected_theme" ]]; then
        _error "No theme selected"
    fi

    _info "Applying theme: $selected_theme..."
    rice-theme set "$selected_theme" || _error "Failed to apply theme"

    # Wallpaper selection
    local selected_wallpaper
    selected_wallpaper=$(show_wallpaper_menu "$selected_theme") || true

    if [[ -n "$selected_wallpaper" ]]; then
        _info "Applying wallpaper..."
        rice-wallpaper set "$selected_wallpaper" || _error "Failed to set wallpaper"
        _info "Theme and wallpaper updated!"
    else
        _info "Theme updated (no wallpaper selected)"
    fi
}

main "$@"
