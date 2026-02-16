#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/icons.sh"
STATE_FILE="/tmp/bmux-bots-state.tsv"

if [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ]; then
    exit 0
fi

CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null)

ATTENTION=0 IDLE=0 RUNNING=0 S_ATTENTION=0 S_IDLE=0 S_RUNNING=0
while IFS=$'\t' read -r _ session_name _ _ _ _ _ _ state; do
    case "$state" in
        attention) ((ATTENTION++)); [ "$session_name" = "$CURRENT_SESSION" ] && ((S_ATTENTION++)) ;;
        idle)      ((IDLE++));      [ "$session_name" = "$CURRENT_SESSION" ] && ((S_IDLE++)) ;;
        running)   ((RUNNING++));   [ "$session_name" = "$CURRENT_SESSION" ] && ((S_RUNNING++)) ;;
    esac
done < "$STATE_FILE"

format_counts() {
    local attn="$1" idle="$2" running="$3" result=""
    [ "$attn" -gt 0 ] && result+="#[fg=yellow,bold]${ICON_ATTENTION} ${attn}#[default]"
    [ "$idle" -gt 0 ] && { [ -n "$result" ] && result+=" "; result+="#[fg=green]${ICON_IDLE} ${idle}#[default]"; }
    [ "$running" -gt 0 ] && { [ -n "$result" ] && result+=" "; result+="#[fg=blue]${ICON_RUNNING} ${running}#[default]"; }
    printf '%s' "$result"
}

OUTPUT=$(format_counts "$ATTENTION" "$IDLE" "$RUNNING")

if [ -n "$OUTPUT" ] && \
   [ "$S_ATTENTION" != "$ATTENTION" -o "$S_IDLE" != "$IDLE" -o "$S_RUNNING" != "$RUNNING" ]; then
    SESS_OUTPUT=$(format_counts "$S_ATTENTION" "$S_IDLE" "$S_RUNNING")
    if [ -n "$SESS_OUTPUT" ]; then
        OUTPUT+=" #[default](${SESS_OUTPUT}#[default])"
    else
        OUTPUT+=" #[default](#[dim]0#[default])"
    fi
fi

# Only show if there are sessions
if [ -n "$OUTPUT" ]; then
    TOTAL=$((ATTENTION + IDLE + RUNNING))
    ICON=$'\xf3\xb1\x9a\x9f'
    echo "${TOTAL}_${ICON}   ${OUTPUT}"
fi
