#!/bin/bash
# =============================================================================
#  Rice Workspace Guard
#  Prevents creation of workspaces beyond 4 in Hyprland
#  Monitors Hyprland events and enforces 4-workspace limit
# =============================================================================

set -euo pipefail

# Configuration
readonly RICE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/rice"
readonly LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/rice-workspace-guard.log"
readonly MAX_WORKSPACES=4
readonly CHECK_INTERVAL=1  # seconds

# Logging
_log() {
    local level="$1"; shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
}

_error() {
    echo "ERROR: $*" >&2
    _log "ERROR" "$@"
}

_info() {
    _log "INFO" "$@"
}

# =============================================================================
#  Hyprland IPC Functions
# =============================================================================
# Get current workspace number
get_active_workspace() {
    hyprctl activewindow -j 2>/dev/null | jq -r '.workspace.id' 2>/dev/null || echo "1"
}

# Get total workspace count
get_workspace_count() {
    hyprctl workspaces -j 2>/dev/null | jq 'length' 2>/dev/null || echo "4"
}

# Switch to workspace (safely)
switch_workspace() {
    local target_ws=$1

    # Clamp to 1-4
    if [[ $target_ws -gt $MAX_WORKSPACES ]]; then
        target_ws=$MAX_WORKSPACES
    elif [[ $target_ws -lt 1 ]]; then
        target_ws=1
    fi

    hyprctl dispatch workspace "$target_ws" 2>/dev/null || true
}

# =============================================================================
#  Workspace Guard Logic
# =============================================================================
enforce_workspace_limit() {
    local current_ws
    current_ws=$(get_active_workspace)
    local ws_count
    ws_count=$(get_workspace_count)

    # If workspace number exceeds MAX_WORKSPACES, switch back
    if [[ $current_ws -gt $MAX_WORKSPACES ]]; then
        _info "Workspace $current_ws detected (exceeds limit of $MAX_WORKSPACES) - switching to workspace $MAX_WORKSPACES"
        switch_workspace "$MAX_WORKSPACES"

        # Notify user
        notify-send \
            -u normal \
            -t 2000 \
            "Workspace Limit" \
            "Maximum 4 workspaces allowed. Switched to workspace 4."
    fi
}

# =============================================================================
#  Event Monitoring (using Hyprland socket)
# =============================================================================
monitor_workspace_events() {
    _info "Starting workspace guard (monitoring up to $MAX_WORKSPACES workspaces)"

    # Main loop: check every CHECK_INTERVAL seconds
    while true; do
        enforce_workspace_limit
        sleep "$CHECK_INTERVAL"
    done
}

# =============================================================================
#  Daemon Management
# =============================================================================
start_daemon() {
    # Check if already running
    if pgrep -f "rice-workspace-guard" > /dev/null 2>&1; then
        _info "Workspace guard already running"
        return 0
    fi

    # Start in background
    monitor_workspace_events &
    local pid=$!

    echo "$pid" > "${XDG_RUNTIME_DIR:-/tmp}/rice-workspace-guard.pid"
    _info "Workspace guard started (PID: $pid)"
}

stop_daemon() {
    local pid_file="${XDG_RUNTIME_DIR:-/tmp}/rice-workspace-guard.pid"

    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")

        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            _info "Workspace guard stopped (PID: $pid)"
        fi

        rm -f "$pid_file"
    fi
}

status_daemon() {
    local pid_file="${XDG_RUNTIME_DIR:-/tmp}/rice-workspace-guard.pid"

    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")

        if kill -0 "$pid" 2>/dev/null; then
            echo "Workspace guard is running (PID: $pid)"
            return 0
        fi
    fi

    echo "Workspace guard is not running"
    return 1
}

# =============================================================================
#  Main
# =============================================================================
main() {
    case "${1:-start}" in
        start)
            start_daemon
            ;;
        stop)
            stop_daemon
            ;;
        restart)
            stop_daemon
            sleep 1
            start_daemon
            ;;
        status)
            status_daemon
            ;;
        check)
            # One-time check (useful for debugging)
            enforce_workspace_limit
            ;;
        *)
            echo "Usage: rice-workspace-guard {start|stop|restart|status|check}"
            echo ""
            echo "Commands:"
            echo "  start      Start the workspace guard daemon"
            echo "  stop       Stop the workspace guard daemon"
            echo "  restart    Restart the daemon"
            echo "  status     Check if daemon is running"
            echo "  check      Perform one-time enforcement check"
            exit 1
            ;;
    esac
}

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

# Run main
main "$@"
