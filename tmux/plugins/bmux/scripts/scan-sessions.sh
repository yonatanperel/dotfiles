#!/bin/bash
STATE_FILE="/tmp/bmux-bots-state.tsv"
HOOK_STATE_DIR="/tmp/bmux-bots"

PANES=$(tmux list-panes -a -F "#{session_name}|#{window_id}|#{window_name}|#{pane_id}|#{pane_title}|#{pane_current_path}" 2>/dev/null)

if [ -z "$PANES" ]; then
    TMPFILE=$(mktemp "${STATE_FILE}.XXXXXX")
    printf '' > "$TMPFILE"
    mv "$TMPFILE" "$STATE_FILE"
    exit 0
fi

LIVE_PANE_IDS=$(echo "$PANES" | cut -d'|' -f4)
for state_file in "$HOOK_STATE_DIR"/*.state; do
    [ -f "$state_file" ] || continue
    pane_id=$(basename "$state_file" .state)
    echo "$LIVE_PANE_IDS" | grep -qxF "$pane_id" || rm -f "$state_file"
done

ENTRIES=""

while IFS='|' read -r session_name window_id window_name pane_id pane_title pane_path; do
    HOOK_STATE_FILE="$HOOK_STATE_DIR/${pane_id}.state"
    [ -f "$HOOK_STATE_FILE" ] || continue

    PROJECT=$(basename "$pane_path")
    STATE="running"
    PRIORITY=1
    LAST_CHANGED=$(stat -f %m "$HOOK_STATE_FILE" 2>/dev/null || date +%s)
    HOOK_STATE=$(<"$HOOK_STATE_FILE")

    case "$HOOK_STATE" in
        attention)
            STATE="attention"
            PRIORITY=0
            ;;
        idle)
            STATE="idle"
            PRIORITY=2
            ;;
    esac

    ENTRIES+="${PRIORITY}	${LAST_CHANGED}	${session_name}	${window_id}	${window_name}	${pane_id}	${pane_title}	${PROJECT}	${pane_path}	${STATE}
"
done <<< "$PANES"

TMPFILE=$(mktemp "${STATE_FILE}.XXXXXX")
if [ -n "$ENTRIES" ]; then
    printf '%s' "$ENTRIES" | sort -t$'\t' -k1,1n -k2,2rn | cut -f2- >> "$TMPFILE"
fi
mv "$TMPFILE" "$STATE_FILE"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/cache-worktrees.sh" &
