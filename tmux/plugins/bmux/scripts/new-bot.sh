#!/usr/bin/env bash

BOTS=($'\U000f06a9' $'\U000f169d' $'\U000f169f' $'\U000f16a1' $'\U000f16a3' $'\U000f1719' $'\U000f16a5' $'\U000ee0d')

session="${1:-$(tmux display-message -p '#S')}"
target_path=$(tmux show-environment -t "$session" SESSION_ROOT_DIR 2>/dev/null | cut -d= -f2-)

used=$(tmux list-windows -t "$session" -F '#W' 2>/dev/null)

available=()
for bot in "${BOTS[@]}"; do
    if ! echo "$used" | grep -qF "$bot"; then
        available+=("$bot")
    fi
done

if [ ${#available[@]} -gt 0 ]; then
    name="${available[$((RANDOM % ${#available[@]}))]}"
else
    name="${BOTS[$((RANDOM % ${#BOTS[@]}))]}"
fi

tmux new-window -t "$session" -n "$name" ${target_path:+-c "$target_path"}
tmux set-option -w -t "$session:$name" @is_bot 1
tmux send-keys -t "$session:$name" "claude" C-m
