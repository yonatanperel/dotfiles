#!/usr/bin/env bash

if [ "$1" = "init_pane" ]; then
    session_dir=$(tmux show-environment -t "$TMUX_PANE" SESSION_ROOT_DIR 2>/dev/null | cut -d= -f2-)
    if [ -n "$session_dir" ] && [ -d "$session_dir" ]; then
        tmux send-keys -t "$TMUX_PANE" "cd '$session_dir'" C-m

        main_repo_dir="$session_dir"
        if [ -f "$session_dir/.git" ] && git -C "$session_dir" rev-parse --git-dir > /dev/null 2>&1; then
            git_common_dir=$(cd "$session_dir" && git rev-parse --git-common-dir 2>/dev/null)
            if [ -n "$git_common_dir" ]; then
                main_repo_dir=$(cd "$session_dir" && cd "$git_common_dir/.." && pwd)
            fi
        fi

        if [ -f "$session_dir/.env" ]; then
            tmux send-keys -t "$TMUX_PANE" "set -a && source .env && set +a" C-m
        fi
        if [ -f "$main_repo_dir/.env.me" ]; then
            tmux send-keys -t "$TMUX_PANE" "set -a && source '$main_repo_dir/.env.me' && set +a" C-m
        fi
        tmux send-keys -t "$TMUX_PANE" "clear" C-m
    fi
    exit 0
fi

