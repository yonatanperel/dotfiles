#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/icons.sh"
STATE_FILE="/tmp/bmux-bots-state.tsv"

bash "$SCRIPT_DIR/scan-sessions.sh"

if [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ]; then
    tmux display-message -d 2000 "${ICON_NONE} No bot sessions found"
    exit 0
fi

CURRENT_PANE=$(tmux display-message -p '#{pane_id}')

SESSION_NAME="" WINDOW_ID="" PANE_ID="" WINDOW_NAME="" PANE_TITLE=""
while IFS=$'\t' read -r _ sn wid wn pid pt _ _ state; do
    if [ "$state" = "attention" ] && [ "$pid" != "$CURRENT_PANE" ]; then
        SESSION_NAME="$sn" WINDOW_ID="$wid" WINDOW_NAME="$wn" PANE_ID="$pid" PANE_TITLE="$pt"
        break
    fi
done < "$STATE_FILE"

if [ -z "$PANE_ID" ]; then
    tmux display-message -d 2000 "${ICON_IDLE} No other bots need attention"
    exit 0
fi

if ! tmux list-panes -a -F "#{pane_id}" | grep -q "^${PANE_ID}$"; then
    tmux display-message -d 2000 "${ICON_ERROR} Pane no longer exists"
    exit 1
fi

tmux switch-client -t "$SESSION_NAME"
tmux select-window -t "$WINDOW_ID"
tmux select-pane -t "$PANE_ID"
BASE=$(cat "/tmp/bmux-bots/${PANE_ID}.name" 2>/dev/null)
CLEAN_TITLE=$(echo "$PANE_TITLE" | sed 's/^[^[:alnum:]]* *//')
tmux display-message -d 2000 "${ICON_JUMP} ${ICON_ATTENTION} ${BASE} ${CLEAN_TITLE} [${SESSION_NAME}]"
