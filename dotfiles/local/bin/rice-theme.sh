#!/bin/bash
# =============================================================================
#  Rice Theme Switcher
#  Switch between themes, update symlinks, apply colors dynamically
# =============================================================================

set -euo pipefail

readonly RICE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/rice"
readonly THEME_DIR="$RICE_DIR/themes"
readonly STATE_FILE="$RICE_DIR/state"
readonly CONFIG_DIR="$HOME/.config"

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
#  Theme Management
# =============================================================================

list_themes() {
    if [[ ! -d "$THEME_DIR" ]]; then
        _error "Theme directory not found: $THEME_DIR"
    fi

    local themes
    mapfile -t themes < <(find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d | sed "s|$THEME_DIR/||" | sort)

    if [[ ${#themes[@]} -eq 0 ]]; then
        _error "No themes found in $THEME_DIR"
    fi

    echo "${themes[@]}"
}

get_active_theme() {
    if [[ -f "$STATE_FILE" ]]; then
        sed -n '1p' "$STATE_FILE" 2>/dev/null || echo "none"
    else
        echo "none"
    fi
}

set_active_theme() {
    local theme=$1
    local wallpaper=${2:-}

    if [[ ! -d "$THEME_DIR/$theme" ]]; then
        _error "Theme not found: $theme"
    fi

    # Update state file
    printf '%s\n%s\n' "$theme" "$wallpaper" > "$STATE_FILE"
    _success "Theme state updated: $theme"
}

apply_theme_symlinks() {
    local theme=$1
    local theme_config="$THEME_DIR/$theme/config"

    if [[ ! -d "$theme_config" ]]; then
        _error "Theme config directory not found: $theme_config"
    fi

    _info "Applying theme symlinks for: $theme"

    # Iterate through each app's config in the theme
    for app_config in "$theme_config"/*/; do
        local app_name
        app_name=$(basename "$app_config")

        if [[ ! -d "$CONFIG_DIR/$app_name" ]]; then
            mkdir -p "$CONFIG_DIR/$app_name"
        fi

        # Symlink each colors.* file
        for colors_file in "$app_config"/colors.*; do
            if [[ -f "$colors_file" ]]; then
                local filename
                filename=$(basename "$colors_file")
                local link_path="$CONFIG_DIR/$app_name/$filename"

                # Backup existing non-symlink file
                if [[ -e "$link_path" ]] && [[ ! -L "$link_path" ]]; then
                    mv "$link_path" "$link_path.backup"
                    _info "Backed up: $link_path.backup"
                fi

                # Create symlink
                rm -f "$link_path"
                ln -sf "$colors_file" "$link_path"
                _success "Symlinked: $app_name/$filename"
            fi
        done
    done
}

reload_hyprland() {
    if ! command -v hyprctl &>/dev/null; then
        _info "Hyprland not running, skipping reload"
        return 0
    fi

    _info "Reloading Hyprland..."
    hyprctl reload 2>/dev/null || _info "Could not reload Hyprland (may not be running)"
}

# =============================================================================
#  Main
# =============================================================================

main() {
    case "${1:-list}" in
        list)
            _info "Available themes:"
            list_themes | nl
            _info "Current theme: $(get_active_theme)"
            ;;
        set)
            if [[ -z "${2:-}" ]]; then
                _error "Usage: rice-theme set <theme_name>"
            fi

            local theme=$2
            apply_theme_symlinks "$theme"
            set_active_theme "$theme"
            reload_hyprland
            _success "Theme '$theme' applied!"
            ;;
        current)
            echo "$(get_active_theme)"
            ;;
        *)
            echo "Usage: rice-theme {list|set|current}"
            echo ""
            echo "Commands:"
            echo "  list           List all available themes"
            echo "  set <theme>    Apply a theme"
            echo "  current        Show current active theme"
            exit 1
            ;;
    esac
}

main "$@"
