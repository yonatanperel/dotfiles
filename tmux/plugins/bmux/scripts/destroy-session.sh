#!/usr/bin/env bash

destroy_session() {
    local current_session=$(tmux display-message -p '#S')
    local session_root_dir=$(tmux show-environment -t "$current_session" SESSION_ROOT_DIR 2>/dev/null | cut -d= -f2-)

    if [ -z "$session_root_dir" ]; then
        echo "Warning: SESSION_ROOT_DIR not set for this session"
        read -p "Continue with session destruction? (y/N): " confirm
        if [ "$confirm" != "y" ]; then
            return 1
        fi
    fi

    echo "=== Session Cleanup for: $current_session ==="
    echo "Root directory: $session_root_dir"
    echo ""

    local is_worktree=false
    local worktree_branch=""
    local main_worktree=""
    local main_repo_name=""

    if [ -n "$session_root_dir" ] && [ -d "$session_root_dir" ]; then
        cd "$session_root_dir"
        if [ -f .git ] && git rev-parse --git-dir > /dev/null 2>&1; then
            is_worktree=true
            worktree_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

            local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
            if [ -n "$git_common_dir" ]; then
                main_worktree=$(cd "$git_common_dir/.." && pwd)
                main_repo_name=$(basename "$main_worktree")
            fi

            echo "Detected git worktree: $worktree_branch"
            echo "Main repository: $main_worktree ($main_repo_name)"
            echo ""
        fi
    fi

    local target_session=""

    if [ -n "$main_repo_name" ]; then
        local repo_session=$(echo "$main_repo_name" | tr './:' '_')
        if tmux has-session -t "$repo_session" 2>/dev/null && [ "$repo_session" != "$current_session" ]; then
            target_session="$repo_session"
            echo "Found main repository session: $target_session"
        fi
    fi

    if [ -z "$target_session" ]; then
        local sessions=$(tmux list-sessions -F '#S' | grep -v "^${current_session}$")
        if [ -z "$sessions" ]; then
            echo "No other sessions available."
            read -p "Create new session before destroying current? (y/N): " create_new
            if [ "$create_new" = "y" ]; then
                tmux new-session -d -s "default"
                target_session="default"
            else
                echo "Cannot destroy the only session. Aborting."
                return 1
            fi
        else
            target_session=$(echo "$sessions" | head -n 1)
            echo "Switching to previous session: $target_session"
        fi
    fi

    if [ "$is_worktree" = true ] && [ -n "$worktree_branch" ] && [ -n "$main_worktree" ]; then
        echo ""
        echo "=== Git Worktree Cleanup ==="

        cd "$main_worktree"

        echo "Removing worktree: $session_root_dir"
        git worktree remove "$session_root_dir" --force

        echo "Deleting local branch: $worktree_branch"
        git branch -D "$worktree_branch"

        echo "Worktree cleanup complete."
    fi

    echo ""
    echo "Switching to session: $target_session"
    tmux switch-client -t "$target_session"

    tmux kill-session -t "$current_session"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    destroy_session "$@"
fi
