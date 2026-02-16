#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/scan-sessions.sh" >/dev/null 2>&1
bash "$SCRIPT_DIR/status-bar-sessions.sh"
