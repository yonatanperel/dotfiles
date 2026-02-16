#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/toggle-attention.sh" "$1"
bash "$SCRIPT_DIR/scan-sessions.sh"
bash "$SCRIPT_DIR/reload-list.sh" "$2"
