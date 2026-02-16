#!/usr/bin/env bash

worktree_close() {
    local session_name="$1"
    local no_confirm="$2"

    if [ -z "$session_name" ]; then
        echo "Error: session name required"
        return 1
    fi

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' does not exist"
        return 1
    fi

    if [ "$no_confirm" != "--no-confirm" ]; then
        printf "Close session '$session_name'? (y/N) "
        read -rsn1 confirm < /dev/tty
        echo
        if [ "$confirm" != "y" ]; then
            echo "Cancelled"
            return 0
        fi
    fi

    local root=$(tmux show-environment -t "$session_name" SESSION_ROOT_DIR 2>/dev/null | cut -d= -f2-)
    local base_repo="$root"
    if [ -n "$root" ] && [ -f "$root/.git" ]; then
        local common_dir=$(cd "$root" && git rev-parse --git-common-dir 2>/dev/null)
        if [ -n "$common_dir" ]; then
            base_repo=$(cd "$root" && cd "$common_dir/.." && pwd)
        fi
    fi

    local sessions_to_kill="$session_name"
    if [ -n "$base_repo" ] && [ "$root" = "$base_repo" ]; then
        while IFS= read -r sess; do
            [ "$sess" = "$session_name" ] && continue
            local sr=$(tmux show-environment -t "$sess" SESSION_ROOT_DIR 2>/dev/null | cut -d= -f2-)
            [ -z "$sr" ] && continue
            local sb="$sr"
            if [ -f "$sr/.git" ]; then
                local cd2=$(cd "$sr" && git rev-parse --git-common-dir 2>/dev/null)
                if [ -n "$cd2" ]; then
                    sb=$(cd "$sr" && cd "$cd2/.." && pwd)
                fi
            fi
            [ "$sb" = "$base_repo" ] && sessions_to_kill+=$'\n'"$sess"
        done < <(tmux list-sessions -F '#{session_name}')
    fi

    local current_session=$(tmux display-message -p '#S' 2>/dev/null)
    local need_switch=false
    while IFS= read -r s; do
        [ -z "$s" ] && continue
        [ "$current_session" = "$s" ] && need_switch=true
    done <<< "$sessions_to_kill"

    if [ "$need_switch" = true ]; then
        local other=$(tmux list-sessions -F '#S' 2>/dev/null | grep -vxF "$sessions_to_kill" | head -1)
        if [ -n "$other" ]; then
            tmux switch-client -t "$other"
        fi
    fi

    while IFS= read -r s; do
        [ -z "$s" ] && continue
        tmux kill-session -t "$s" 2>/dev/null
    done <<< "$sessions_to_kill"
    echo "Session '$session_name' closed"
}

worktree_close "$@"
