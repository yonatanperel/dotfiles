#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

session_count=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')
[ "$session_count" -gt 1 ] && exit 0

initial_session=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | head -1)

default_project=$(bash "$SCRIPT_DIR/parse-config.sh" default_project)
[ -z "$default_project" ] && exit 0

project_path=""
while IFS= read -r dir_pattern; do
    [ -z "$dir_pattern" ] && continue
    for dir in $dir_pattern; do
        [ -d "$dir" ] || continue
        if [ "$(basename "$dir")" = "$default_project" ]; then
            project_path="$dir"
            break 2
        fi
    done
done < <(bash "$SCRIPT_DIR/parse-config.sh" project_dirs)

[ -z "$project_path" ] && exit 0

bash "$SCRIPT_DIR/create-session.sh" "$project_path"

if [ -n "$initial_session" ] && tmux has-session -t "=$initial_session" 2>/dev/null; then
    initialized=$(tmux show-environment -t "=$initial_session" SESSION_INITIALIZED 2>/dev/null | cut -d= -f2-)
    [ "$initialized" != "1" ] && tmux kill-session -t "=$initial_session" 2>/dev/null
fi
