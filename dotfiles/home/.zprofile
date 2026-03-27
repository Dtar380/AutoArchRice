# .zprofile — session-level setup
# Start Hyprland automatically if on TTY1 and not already in a compositor
if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" -eq 1 ]]; then
    exec Hyprland
fi
