#!/usr/bin/env bash

worktree_remove() {
    local wt_path="$1"
    local session_name="$2"
    local no_confirm="$3"
    local main_repo="$4"

    if [ -z "$wt_path" ]; then
        echo "Error: worktree path required"
        return 1
    fi

    local branch=""

    if [ -d "$wt_path" ]; then
        if [ ! -f "$wt_path/.git" ]; then
            echo "Error: cannot remove main repository"
            return 1
        fi
        branch=$(git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [ -z "$main_repo" ]; then
            local common_dir=$(cd "$wt_path" && git rev-parse --git-common-dir 2>/dev/null)
            main_repo=$(cd "$wt_path" && cd "$common_dir/.." && pwd)
        fi
    else
        branch=$(basename "$wt_path")
    fi

    if [ -z "$main_repo" ]; then
        echo "Error: cannot determine main repository"
        return 1
    fi

    if [ "$no_confirm" != "--no-confirm" ]; then
        printf "Remove worktree '$(basename "$wt_path")'? This deletes the worktree, branch, and session. (y/N) "
        read -rsn1 confirm < /dev/tty
        echo
        if [ "$confirm" != "y" ]; then
            echo "Cancelled"
            return 0
        fi
    fi

    if [ -n "$session_name" ] && tmux has-session -t "$session_name" 2>/dev/null; then
        local current_session=$(tmux display-message -p '#S' 2>/dev/null)
        if [ "$current_session" = "$session_name" ]; then
            local other=$(tmux list-sessions -F '#S' 2>/dev/null | grep -v "^${session_name}$" | head -1)
            if [ -n "$other" ]; then
                tmux switch-client -t "$other"
            fi
        fi
        tmux kill-session -t "$session_name"
    fi

    cd "$main_repo"
    if [ -d "$wt_path" ]; then
        git worktree remove "$wt_path" --force
    else
        git worktree prune
    fi
    if [ -n "$branch" ]; then
        git branch -D "$branch" 2>/dev/null
    fi
}

worktree_remove "$@"
