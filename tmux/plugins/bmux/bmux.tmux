#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Hooks — auto cd + source env in new panes
tmux set-hook -g after-new-window "run-shell '$CURRENT_DIR/scripts/auto-session-cd.sh init_pane'"
tmux set-hook -g after-split-window "run-shell '$CURRENT_DIR/scripts/auto-session-cd.sh init_pane'"

# Command aliases
tmux set -g command-alias[100] BmuxNewBot="run-shell 'bash $CURRENT_DIR/scripts/new-bot.sh'"
tmux set -g command-alias[101] BmuxNewWorktree="display-popup -E -w 70% -h 60% 'bash $CURRENT_DIR/scripts/new-worktree.sh'"
tmux set -g command-alias[102] BmuxDestroy="run-shell '$CURRENT_DIR/scripts/destroy-session.sh'"
tmux set -g command-alias[103] BmuxBrowse="display-popup -E -w 70% -h 60% 'bash $CURRENT_DIR/scripts/unified-browser.sh'"
tmux set -g command-alias[104] BmuxJumpAttention="run-shell 'bash $CURRENT_DIR/scripts/jump-to-attention.sh'"
tmux set -g command-alias[105] BmuxDismiss="run-shell 'bash $CURRENT_DIR/scripts/update-state.sh dismiss'"

# Status bar interpolation — replace #{bmux_status} in status-right
STATUS_RIGHT=$(tmux show-option -gv status-right)
if [[ "$STATUS_RIGHT" == *'#{bmux_status}'* ]]; then
    STATUS_RIGHT="${STATUS_RIGHT//'#{bmux_status}'/#(bash $CURRENT_DIR/scripts/status.sh)}"
    tmux set-option -g status-right "$STATUS_RIGHT"
fi

# Auto-create default project session on startup
bash "$CURRENT_DIR/scripts/startup.sh" &
