#!/usr/bin/env bash
set -euo pipefail

CLAUDE_SETTINGS="$HOME/.config/claude/settings.json"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

setup_claude_hooks() {
    local hooks
    hooks=$(cat <<'HOOKS'
{
  "SessionStart": [{"hooks": [{"type": "command", "command": "bash ~/.config/tmux/plugins/bmux/scripts/update-state.sh session_start"}]}],
  "Stop": [{"hooks": [{"type": "command", "command": "bash ~/.config/tmux/plugins/bmux/scripts/update-state.sh stop"}]}],
  "Notification": [{"hooks": [{"type": "command", "command": "bash ~/.config/tmux/plugins/bmux/scripts/update-state.sh notification"}]}],
  "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash ~/.config/tmux/plugins/bmux/scripts/update-state.sh prompt_submit"}]}],
  "PreToolUse": [{"hooks": [{"type": "command", "command": "bash ~/.config/tmux/plugins/bmux/scripts/update-state.sh running"}]}],
  "PostToolUse": [{"hooks": [{"type": "command", "command": "bash ~/.config/tmux/plugins/bmux/scripts/update-state.sh running"}]}],
  "SessionEnd": [{"hooks": [{"type": "command", "command": "bash ~/.config/tmux/plugins/bmux/scripts/update-state.sh exit"}]}]
}
HOOKS
)

    mkdir -p "$(dirname "$CLAUDE_SETTINGS")"

    if [ ! -f "$CLAUDE_SETTINGS" ]; then
        echo '{}' > "$CLAUDE_SETTINGS"
    fi

    if jq -e '.hooks.SessionStart[0].hooks[0].command | test("bmux")' "$CLAUDE_SETTINGS" &>/dev/null; then
        info "Claude hooks already configured for bmux"
        return
    fi

    local existing_hooks
    existing_hooks=$(jq -r '.hooks // empty' "$CLAUDE_SETTINGS")

    if [ -n "$existing_hooks" ]; then
        warn "Claude settings already has hooks — merging bmux hooks"
    fi

    local updated
    updated=$(jq --argjson bmux_hooks "$hooks" '.hooks = ((.hooks // {}) * $bmux_hooks)' "$CLAUDE_SETTINGS")
    echo "$updated" > "$CLAUDE_SETTINGS"
    info "Claude hooks configured"
}

echo ""
echo "bmux installer"
echo "=============="
echo ""

setup_claude_hooks

echo ""
info "Done!"
echo ""
