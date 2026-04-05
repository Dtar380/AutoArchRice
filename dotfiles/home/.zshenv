# =============================================================================
#  .zshenv
# =============================================================================
# App variables
export EDITOR=nvim
export VISUAL=nvim
export PAGER=bat

# Add ~/.local/bin to PATH variable
export PATH="$HOME/.local/bin:$PATH"

# XDG configuration
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Qt theming
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
