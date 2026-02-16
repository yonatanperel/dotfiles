#!/bin/bash
WORKTREE_CACHE="/tmp/bmux-worktree-cache"
LOCK="/tmp/bmux-worktree-cache.lock"

if ! mkdir "$LOCK" 2>/dev/null; then exit 0; fi
trap "rmdir '$LOCK'" EXIT

WT_TMP=$(mktemp "${WORKTREE_CACHE}.XXXXXX")
trap "rm -f '$WT_TMP'; rmdir '$LOCK'" EXIT

repo_list=""
while IFS= read -r sess; do
    root=$(tmux show-environment -t "$sess" SESSION_ROOT_DIR 2>/dev/null | cut -d= -f2-)
    [ -z "$root" ] && root=$(tmux display-message -t "$sess" -p '#{pane_current_path}' 2>/dev/null)
    if [ -n "$root" ] && [ -d "$root" ]; then
        base_repo="$root"
        if [ -f "$root/.git" ]; then
            common_dir=$(cd "$root" && git rev-parse --git-common-dir 2>/dev/null)
            if [ -n "$common_dir" ]; then
                base_repo=$(cd "$root" && cd "$common_dir/.." && pwd)
            fi
        fi
        printf 'S|%s|%s|%s\n' "$sess" "$root" "$base_repo" >> "$WT_TMP"
        if [[ "$repo_list" != *"|$base_repo|"* ]]; then
            repo_list+="|$base_repo|"
            if git -C "$base_repo" rev-parse --git-dir > /dev/null 2>&1; then
                git -C "$base_repo" worktree list --porcelain 2>/dev/null | while IFS= read -r line; do
                    if [[ "$line" == "worktree "* ]]; then
                        printf 'W|%s|%s\n' "${line#worktree }" "$base_repo" >> "$WT_TMP"
                    fi
                done
            fi
        fi
    fi
done < <(tmux list-sessions -F '#{session_name}')

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_cache_repo() {
    local dir="$1"
    git -C "$dir" rev-parse --git-dir > /dev/null 2>&1 || return
    local base_repo="$dir"
    if [ -f "$dir/.git" ]; then
        local common_dir=$(cd "$dir" && git rev-parse --git-common-dir 2>/dev/null)
        if [ -n "$common_dir" ]; then
            base_repo=$(cd "$dir" && cd "$common_dir/.." && pwd)
        fi
    fi
    if [[ "$repo_list" != *"|$base_repo|"* ]]; then
        repo_list+="|$base_repo|"
        git -C "$base_repo" worktree list --porcelain 2>/dev/null | while IFS= read -r line; do
            if [[ "$line" == "worktree "* ]]; then
                printf 'W|%s|%s\n' "${line#worktree }" "$base_repo" >> "$WT_TMP"
            fi
        done
    fi
}

while IFS= read -r project_dir; do
    [ -z "$project_dir" ] && continue
    if [[ "$project_dir" == *'/*' ]]; then
        project_dir="${project_dir%/\*}"
        [ -d "$project_dir" ] || continue
        for subdir in "$project_dir"/*/; do
            [ -d "$subdir" ] || continue
            _cache_repo "${subdir%/}"
        done
    else
        [ -d "$project_dir" ] || continue
        _cache_repo "$project_dir"
    fi
done < <(bash "$SCRIPT_DIR/parse-config.sh" project_dirs)

mv "$WT_TMP" "$WORKTREE_CACHE"
