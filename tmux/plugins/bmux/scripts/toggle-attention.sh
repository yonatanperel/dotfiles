#!/bin/bash
# Toggle attention/idle state for a given pane
PANE_ID="$1"
HOOK_STATE_DIR="/tmp/bmux-bots"
STATE_FILE="${HOOK_STATE_DIR}/${PANE_ID}.state"

if [ -f "$STATE_FILE" ]; then
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null)
    if [ "$CURRENT" = "attention" ]; then
        echo "idle" > "$STATE_FILE"
    elif [ "$CURRENT" = "idle" ]; then
        echo "attention" > "$STATE_FILE"
    fi
fi
