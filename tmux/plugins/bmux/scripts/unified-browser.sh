#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

create_script=$(tmux show-environment -g TMUX_AUTO_SESSION_CREATE_SCRIPT 2>/dev/null | cut -d= -f2-)
if [ -z "$create_script" ]; then
    create_script="$SCRIPT_DIR/create-session.sh"
fi

current_session=$(tmux display-message -p '#S')
tmp_action=$(mktemp)
tmp_entries=$(mktemp)
tmp_mode=$(mktemp)
echo "normal" > "$tmp_mode"
trap "rm -f '$tmp_action' '$tmp_entries' '$tmp_mode'" EXIT

pk="a,b,c,e,f,g,h,i,l,m,o,p,r,s,t,u,v,w,z,0,1,2,3,4,5,6,7,8,9,space"
ib="${pk//,/:ignore,}:ignore"

while true; do
    echo "" > "$tmp_action"

    bash "$SCRIPT_DIR/unified-list.sh" "$current_session" --cached > "$tmp_entries"
    selected=$(cat "$tmp_entries" | fzf --ansi \
        --disabled \
        --layout=reverse \
        --delimiter $'\t' \
        --with-nth 2 \
        --no-sort \
        --no-info \
        --no-hscroll \
        --no-scrollbar \
        --pointer='' \
        --marker='' \
        --ellipsis='' \
        --no-header \
        --prompt '||| ' \
        --bind "$ib" \
        --bind "load:pos(2)" \
        --bind "result:transform(echo {} | cut -f1 | grep -q '^header' && echo down)" \
        --bind "j:down+transform(echo {} | cut -f1 | grep -q '^header' && echo down)" \
        --bind "k:up+transform(echo {} | cut -f1 | grep -q '^header' && { [ {n} -eq 0 ] && echo down || echo up; })" \
        --bind "down:down+transform(echo {} | cut -f1 | grep -q '^header' && echo down)" \
        --bind "up:up+transform(echo {} | cut -f1 | grep -q '^header' && { [ {n} -eq 0 ] && echo down || echo up; })" \
        --bind 'q:abort' \
        --bind "ctrl-j:transform(bash '$SCRIPT_DIR/jump-worktree.sh' next {n} '$tmp_entries' '$tmp_mode')" \
        --bind "ctrl-k:transform(bash '$SCRIPT_DIR/jump-worktree.sh' prev {n} '$tmp_entries' '$tmp_mode')" \
        --bind "/:execute-silent(echo search > '$tmp_mode')+unbind(j,k,d,x,a,q,S,A,$pk)+reload(bash '$SCRIPT_DIR/unified-list.sh' '$current_session' --search | tee '$tmp_entries')+enable-search+transform-prompt(printf '/ ')" \
        --bind "esc:execute-silent(echo normal > '$tmp_mode')+reload(bash '$SCRIPT_DIR/reload-list.sh' '$current_session' > '$tmp_entries'; cat '$tmp_entries')+rebind(j,k,d,x,a,q,/,S,A,$pk)+disable-search+clear-query+transform-prompt(printf '||| ')" \
        --bind "d:execute-silent(echo close > '$tmp_action')+accept" \
        --bind "x:execute-silent(echo remove > '$tmp_action')+accept" \
        --bind "S:execute-silent(echo new-worktree > '$tmp_action')+accept" \
        --bind "A:execute-silent(echo new-bot > '$tmp_action')+accept" \
        --bind "a:reload(
            type=\$(echo {} | cut -f1 | cut -d'|' -f1)
            if [ \"\$type\" = \"claude\" ]; then
                pane_id=\$(echo {} | cut -f1 | cut -d'|' -f2)
                bash '$SCRIPT_DIR/toggle-and-reload.sh' \"\$pane_id\" '$current_session' > '$tmp_entries'
            fi
            cat '$tmp_entries'
        )")

    if [ -z "$selected" ]; then
        exit 0
    fi

    read -r action < "$tmp_action" 2>/dev/null

    meta="${selected%%	*}"
    IFS='|' read -r type field1 field2 field3 field4 field5 <<< "$meta"

    if [ "$type" = "bot" ]; then
        # Format: bot|pane_id|window_id|session_name|state
        PANE_ID="$field1"
        WINDOW_ID="$field2"
        SESSION_NAME="$field3"

        if [ -n "$PANE_ID" ] && [ "$PANE_ID" != "null" ]; then
            tmux switch-client -t "$SESSION_NAME"
            tmux select-window -t "$WINDOW_ID"
            tmux select-pane -t "$PANE_ID"
        fi
        break
    fi

    # Format: worktree|path|session|status|base_repo
    path="$field1"
    session="$field2"
    status="$field3"
    base_repo="$field4"

    if [ "$action" = "close" ]; then
        if [ "$type" = "worktree" ] && [ -n "$session" ]; then
            clear
            printf "\n  Close session '\033[33m%s\033[0m'? (y/n) " "$session"
            read -rsn1 confirm < /dev/tty
            if [ "$confirm" = "y" ]; then
                if [ "$session" = "$current_session" ]; then
                    local other=$(tmux list-sessions -F '#S' 2>/dev/null | grep -v "^${session}$" | head -1)
                    if [ -n "$other" ]; then
                        tmux switch-client -t "$other"
                    fi
                fi
                bash "$SCRIPT_DIR/worktree-close.sh" "$session" --no-confirm > /dev/null 2>&1
                bash "$SCRIPT_DIR/cache-worktrees.sh"
                bash "$SCRIPT_DIR/scan-sessions.sh"
                current_session=$(tmux display-message -p '#S' 2>/dev/null)
            fi
        fi
        continue
    elif [ "$action" = "remove" ]; then
        if [ "$type" = "worktree" ] && [ "$path" != "$base_repo" ]; then
            clear
            printf "\n  Remove worktree '\033[33m%s\033[0m'? (y/n) " "${path##*/}"
            read -rsn1 confirm < /dev/tty
            if [ "$confirm" = "y" ]; then
                printf "\n\n  \033[90mRemoving...\033[0m"
                bash "$SCRIPT_DIR/worktree-remove.sh" "$path" "$session" --no-confirm "$base_repo" > /dev/null 2>&1
                bash "$SCRIPT_DIR/cache-worktrees.sh"
                bash "$SCRIPT_DIR/scan-sessions.sh"
                printf "\r  \033[32mRemoved.\033[0m  "
                sleep 0.5
            fi
        fi
        continue
    fi

    if [ "$action" = "new-bot" ]; then
        if [ -n "$session" ]; then
            bash "$SCRIPT_DIR/new-bot.sh" "$session"
        fi
        continue
    elif [ "$action" = "new-worktree" ]; then
        repo="$field4"
        if [ -n "$repo" ] && [ -d "$repo" ]; then
            exec bash "$SCRIPT_DIR/new-worktree.sh" "$repo"
        fi
        continue
    fi

    if [ "$type" = "header" ]; then
        continue
    fi

    if [ "$status" = "active" ] && [ -n "$session" ]; then
        tmux switch-client -t "$session"
    else
        bash "$create_script" "$path"
    fi
    break
done
