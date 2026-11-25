#!/usr/bin/env bash
# Open a file from the Godot editor (Windows) in nvim (WSL).
# Usage: godot-open.sh <windows-or-wsl-path> [line0] [col0]
# Godot passes 1-based {line}/{col}.
SOCK=/tmp/godot-nvim.pipe
file=$(wslpath -u "$1" 2>/dev/null || echo "$1")
line=${2:-1}
col=${3:-1}

if [ -S "$SOCK" ] && nvim --server "$SOCK" --remote-expr "1" >/dev/null 2>&1; then
  esc=${file//\'/\'\'}
  nvim --server "$SOCK" --remote-expr \
    "execute('edit ' . fnameescape('$esc') . ' | call cursor($line, $col)')" >/dev/null
else
  # No running nvim: open one in a new Windows Terminal window.
  wt.exe wsl.exe --cd "$(dirname "$file")" -e nvim "+call cursor($line,$col)" "$file" >/dev/null 2>&1 &
fi
