#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/icons.sh"
HOOK_TYPE="${1:-unknown}"
STATE_DIR="/tmp/bmux-bots"

mkdir -p "$STATE_DIR"

terminal_is_focused() {
    local frontmost="${1:-$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)}"
    [[ "$frontmost" == *Ghostty* || "$frontmost" == *wezterm* || "$frontmost" == *Terminal* || "$frontmost" == *iTerm* || "$frontmost" == *kitty* || "$frontmost" == *Alacritty* ]]
}

notify_macos() {
    local title="$1" message="$2" group="$3"
    terminal-notifier \
        -title "$title" \
        -message "$message" \
        -sound default \
        -group "$group" &
}

dismiss_notification() {
    local group="$1"
    terminal-notifier -remove "$group" &>/dev/null &
}

update_window_name() {
    local pane="$1" state="$2"
    local base_file="$STATE_DIR/${pane}.name"
    local base=$(cat "$base_file" 2>/dev/null)
    [ -z "$base" ] && return
    local icon=""
    case "$state" in
        idle)      icon="$ICON_IDLE" ;;
        running)   icon="$ICON_RUNNING" ;;
        attention) icon="$ICON_ATTENTION" ;;
    esac
    tmux rename-window -t "$pane" "${base} ${icon}" 2>/dev/null
}

base_window_name() {
    local pane="$1"
    cat "$STATE_DIR/${pane}.name" 2>/dev/null
}

set_attention() {
    local frontmost="$1"
    local session_name=$(tmux display-message -p -t "$PANE_ID" '#{session_name}' 2>/dev/null)
    local base=$(base_window_name "$PANE_ID")
    local pane_title=$(tmux display-message -p -t "$PANE_ID" '#{pane_title}' 2>/dev/null | sed 's/^[^[:alnum:]]* *//')
    echo "attention" > "$STATE_FILE"
    update_window_name "$PANE_ID" "attention"
    if ! terminal_is_focused "$frontmost"; then
        notify_macos "🤖 ${pane_title}" "[${session_name}] needs attention" "bmux-${PANE_ID}"
    fi
    local pane_focused=$(tmux list-panes -a -F '#{pane_active}#{window_active}#{session_attached} #{pane_id}' 2>/dev/null | grep -q "^111 ${PANE_ID}$" && echo 1)
    if [ "$pane_focused" != "1" ]; then
        tmux display-message -d 2000 "${ICON_INCOMING} ${ICON_ATTENTION} ${base} ${pane_title} [${session_name}]" &
    fi
    tmux refresh-client -S &
}

if [ "$HOOK_TYPE" = "dismiss" ]; then
    PANE_ID=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
    STATE_FILE="$STATE_DIR/${PANE_ID}.state"
    if [ -f "$STATE_FILE" ]; then
        CURRENT=$(cat "$STATE_FILE" 2>/dev/null)
        BASE=$(base_window_name "$PANE_ID")
        PANE_TITLE=$(tmux display-message -p '#{pane_title}' 2>/dev/null | sed 's/^[^[:alnum:]]* *//')
        SESSION_NAME=$(tmux display-message -p '#{session_name}' 2>/dev/null)
        if [ "$CURRENT" = "attention" ]; then
            echo "idle" > "$STATE_FILE"
            dismiss_notification "bmux-${PANE_ID}"
            update_window_name "$PANE_ID" "idle"
            tmux display-message -d 2000 "${ICON_IDLE} ${BASE} ${PANE_TITLE} [${SESSION_NAME}]"
        elif [ "$CURRENT" = "idle" ]; then
            echo "attention" > "$STATE_FILE"
            update_window_name "$PANE_ID" "attention"
            tmux display-message -d 2000 "${ICON_ATTENTION} ${BASE} ${PANE_TITLE} [${SESSION_NAME}]"
        fi
        tmux refresh-client -S &
    fi
    exit 0
fi

cat > /dev/null

PANE_ID="${TMUX_PANE}"
if [ -z "$PANE_ID" ]; then
    exit 0
fi

STATE_FILE="$STATE_DIR/${PANE_ID}.state"

echo "$(date +%H:%M:%S) hook=$HOOK_TYPE pane=$PANE_ID" >> "$STATE_DIR/debug.log"

case "$HOOK_TYPE" in
    session_start)
        echo "idle" > "$STATE_FILE"
        if [ ! -s "$STATE_DIR/${PANE_ID}.name" ]; then
            tmux display-message -p -t "$PANE_ID" '#{window_name}' > "$STATE_DIR/${PANE_ID}.name" 2>/dev/null
        fi
        update_window_name "$PANE_ID" "idle"
        ;;
    prompt_submit|running)
        echo "running" > "$STATE_FILE"
        dismiss_notification "bmux-${PANE_ID}"
        update_window_name "$PANE_ID" "running"
        ;;
    stop)
        FRONTMOST=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
        PANE_FOCUSED=$(tmux list-panes -a -F '#{pane_active}#{window_active}#{session_attached} #{pane_id}' 2>/dev/null | grep -q "^111 ${PANE_ID}$" && echo 1)
        if [ "$PANE_FOCUSED" = "1" ] && terminal_is_focused "$FRONTMOST"; then
            echo "idle" > "$STATE_FILE"
            update_window_name "$PANE_ID" "idle"
        else
            set_attention "$FRONTMOST"
        fi
        tmux refresh-client -S &
        ;;
    exit)
        base=$(base_window_name "$PANE_ID")
        [ -n "$base" ] && tmux rename-window -t "$PANE_ID" "$base" 2>/dev/null
        rm -f "$STATE_FILE" "$STATE_DIR/${PANE_ID}.name"
        dismiss_notification "bmux-${PANE_ID}"
        tmux refresh-client -S &
        ;;
    notification)
        set_attention ""
        ;;
esac
