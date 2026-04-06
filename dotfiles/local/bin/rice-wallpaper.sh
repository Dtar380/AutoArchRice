#!/bin/bash
# =============================================================================
#  Rice Wallpaper Switcher
#  Change wallpapers within current theme
# =============================================================================

set -euo pipefail

readonly RICE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/rice"
readonly STATE_FILE="$RICE_DIR/state"
readonly WALLPAPER_LINK="$HOME/Images/wallpaper"

# Logging
_error() {
    echo "ERROR: $*" >&2
    exit 1
}

_info() {
    echo "INFO: $*"
}

_success() {
    echo "✓ $*"
}

# =============================================================================
#  Wallpaper Management
# =============================================================================

get_active_theme() {
    if [[ -f "$STATE_FILE" ]]; then
        sed -n '1p' "$STATE_FILE" 2>/dev/null || echo "none"
    else
        echo "none"
    fi
}

get_active_wallpaper() {
    if [[ -f "$STATE_FILE" ]]; then
        sed -n '2p' "$STATE_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

list_wallpapers() {
    local theme=$1
    local wallpaper_dir="$RICE_DIR/themes/$theme/wallpapers"

    if [[ ! -d "$wallpaper_dir" ]]; then
        _error "Wallpaper directory not found: $wallpaper_dir"
    fi

    find "$wallpaper_dir" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | \
        sed "s|$wallpaper_dir/||" | sort
}

set_wallpaper() {
    local theme=$1
    local wallpaper=$2
    local wallpaper_path="$RICE_DIR/themes/$theme/wallpapers/$wallpaper"

    if [[ ! -f "$wallpaper_path" ]]; then
        _error "Wallpaper not found: $wallpaper_path"
    fi

    # Get file extension
    local ext="${wallpaper_path##*.}"

    # Create symlink in ~/Images/
    mkdir -p "$HOME/Images"
    rm -f "$WALLPAPER_LINK".*
    ln -sf "$wallpaper_path" "$WALLPAPER_LINK.$ext"
    _success "Wallpaper set: $wallpaper"

    # Update state file
    local current_theme
    current_theme=$(get_active_theme)
    printf '%s\n%s\n' "$current_theme" "$wallpaper" > "$STATE_FILE"
    _success "State updated"

    # Reload swww or apply to Hyprland (for hyprlock, etc)
    if command -v swww &>/dev/null && pgrep -x "swww-daemon" > /dev/null 2>&1; then
        _info "Updating wallpaper with swww..."
        swww img "$wallpaper_path" --transition-type wipe 2>/dev/null || true
    fi
}

# =============================================================================
#  Main
# =============================================================================

main() {
    local active_theme
    active_theme=$(get_active_theme)

    if [[ "$active_theme" == "none" ]]; then
        _error "No active theme. Use 'rice-theme set <theme>' first."
    fi

    case "${1:-list}" in
        list)
            _info "Wallpapers for theme: $active_theme"
            list_wallpapers "$active_theme" | nl
            _info "Current: $(get_active_wallpaper)"
            ;;
        set)
            if [[ -z "${2:-}" ]]; then
                _error "Usage: rice-wallpaper set <wallpaper_file>"
            fi
            set_wallpaper "$active_theme" "$2"
            ;;
        current)
            echo "$(get_active_wallpaper)"
            ;;
        *)
            echo "Usage: rice-wallpaper {list|set|current}"
            echo ""
            echo "Commands:"
            echo "  list              List wallpapers in current theme"
            echo "  set <wallpaper>   Apply a wallpaper"
            echo "  current           Show current wallpaper"
            exit 1
            ;;
    esac
}

main "$@"
