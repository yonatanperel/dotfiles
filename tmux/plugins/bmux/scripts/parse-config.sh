#!/usr/bin/env bash

mode="$1"
project_path="$2"

CONFIG_FILE="${BMUX_CONFIG:-$HOME/.config/bmux/bmux.yaml}"

if [ ! -f "$CONFIG_FILE" ]; then
    exit 0
fi

project_name=""
if [ -n "$project_path" ]; then
    project_name="${project_path##*/}"
fi

if [ -n "$project_name" ] && yq -e ".projects.$project_name" "$CONFIG_FILE" > /dev/null 2>&1; then
    base=".projects.$project_name"
else
    base=".default"
fi

block=$(yq -o=json "$base" "$CONFIG_FILE" 2>/dev/null)
[ -z "$block" ] || [ "$block" = "null" ] && exit 0

case "$mode" in
    default_project)
        dp=$(yq -r '.projects | to_entries[] | select(.value.default == true) | .key' "$CONFIG_FILE" 2>/dev/null | head -1)
        if [ -z "$dp" ]; then
            dp=$(yq -r '.projects | keys | .[0]' "$CONFIG_FILE" 2>/dev/null)
        fi
        [ -n "$dp" ] && [ "$dp" != "null" ] && echo "$dp"
        exit 0
        ;;
    project_dirs)
        yq -r '.project_dirs // [] | .[]' "$CONFIG_FILE" 2>/dev/null | sed "s|^~|$HOME|"
        exit 0
        ;;
    windows)
        echo "$block" | jq -r '.windows // [] | .[] | .name'
        ;;
    window_commands)
        echo "$block" | jq -r '.windows // [] | .[] | if .commands then (.commands | join("\n")) elif .command then .command else "" end, "---"'
        ;;
    worktree_dir)
        echo "$block" | jq -r '.worktree.dir // empty'
        ;;
    worktree_symlinks)
        echo "$block" | jq -r '.worktree.symlinks // [] | .[]'
        ;;
    worktree_copies)
        echo "$block" | jq -r '.worktree.copies // [] | .[]'
        ;;
    env)
        echo "$block" | jq -r '.env // [] | .[]'
        ;;
    linear)
        echo "$block" | jq -r '.linear // {} | to_entries[] | "\(.key)\t\(.value)"'
        ;;
esac
