#!/usr/bin/env bash

create_session() {
    local target_path="$1"

    if [ -z "$target_path" ]; then
        echo "Error: Path required"
        echo "Usage: create-session.sh <path>"
        return 1
    fi

    if [ ! -d "$target_path" ]; then
        echo "Error: Directory does not exist: $target_path"
        return 1
    fi

    target_path=$(cd "$target_path" && pwd)

    local session_name
    cd "$target_path"

    if git rev-parse --git-dir > /dev/null 2>&1; then
        if [ -f .git ]; then
            session_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        else
            session_name=$(basename "$target_path")
        fi
    else
        session_name=$(basename "$target_path")
    fi

    session_name=$(echo "$session_name" | tr './:' '_')

    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' already exists. Switching to it."
        tmux switch-client -t "$session_name" 2>/dev/null || tmux attach-session -t "$session_name"
        return 0
    fi

    tmux new-session -d -s "$session_name" -c "$target_path"

    tmux set-environment -t "$session_name" SESSION_ROOT_DIR "$target_path"
    tmux set-environment -t "$session_name" SESSION_INITIALIZED "1"

    # Use common setup script
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    "$script_dir/setup-session.sh" "$session_name" "$target_path"

    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$session_name"
    else
        tmux attach-session -t "$session_name"
    fi
}

create_session "$@"
