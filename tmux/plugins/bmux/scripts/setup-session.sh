#!/usr/bin/env bash

# Common session setup logic used by both auto-cd and explicit session creation
# Usage: setup-session.sh <session_name> <target_path>

setup_session() {
    local session_name="$1"
    local target_path="$2"

    if [ -z "$session_name" ] || [ -z "$target_path" ]; then
        echo "Error: session_name and target_path required"
        return 1
    fi

    # Determine main repo directory (for .env.me)
    local main_repo_dir="$target_path"
    if [ -f "$target_path/.git" ] && git -C "$target_path" rev-parse --git-dir > /dev/null 2>&1; then
        local git_common_dir=$(cd "$target_path" && git rev-parse --git-common-dir 2>/dev/null)
        if [ -n "$git_common_dir" ]; then
            main_repo_dir=$(cd "$target_path" && cd "$git_common_dir/.." && pwd)
        fi
    fi

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    local env_cmds=()
    while IFS= read -r env_file; do
        [ -z "$env_file" ] && continue
        if [ -f "$main_repo_dir/$env_file" ]; then
            env_cmds+=("set -a && source '$main_repo_dir/$env_file' && set +a")
        fi
    done < <(bash "$script_dir/parse-config.sh" env "$main_repo_dir")

    source_env_in_window() {
        local target="$1"
        for cmd in "${env_cmds[@]}"; do
            tmux send-keys -t "$target" "$cmd" C-m
        done
        if [ ${#env_cmds[@]} -gt 0 ]; then
            tmux send-keys -t "$target" "clear" C-m
        fi
    }

    # Phase 1: Create all reserved windows (no commands yet)
    local win_idx=1
    local -a window_indices=()

    while IFS= read -r wname; do
        [ -z "$wname" ] && continue
        if [ "$win_idx" -eq 1 ]; then
            tmux rename-window -t "$session_name:1" "$wname"
        else
            tmux new-window -t "$session_name" -n "$wname" -c "$target_path"
        fi
        source_env_in_window "$session_name:$win_idx"
        window_indices+=("$win_idx")
        win_idx=$((win_idx + 1))
    done < <(bash "$script_dir/parse-config.sh" windows "$main_repo_dir")

    # Phase 2: Create and start bot window
    local bot_name=$'\U000f06a9'
    if [ "$win_idx" -eq 1 ]; then
        tmux rename-window -t "$session_name:1" "$bot_name"
    else
        tmux new-window -t "$session_name" -n "$bot_name" -c "$target_path"
    fi
    tmux set-option -w -t "$session_name:$win_idx" @is_bot 1
    source_env_in_window "$session_name:$win_idx"
    tmux send-keys -t "$session_name:$win_idx" "claude" C-m
    tmux select-window -t "$session_name:$win_idx"

    # Phase 3: Run commands on reserved windows
    local widx_pos=0
    local widx=""
    while IFS= read -r line; do
        if [ "$line" = "---" ]; then
            widx_pos=$((widx_pos + 1))
            continue
        fi
        [ -z "$line" ] && continue
        widx="${window_indices[$widx_pos]}"
        tmux send-keys -t "$session_name:$widx" "$line" C-m
    done < <(bash "$script_dir/parse-config.sh" window_commands "$main_repo_dir")
}

setup_session "$@"
