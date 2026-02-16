#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/icons.sh"

current_session="$1"
if [ -z "$current_session" ]; then
    current_session=$(tmux display-message -p '#S' 2>/dev/null)
fi
cached_only=""
search_mode=""
for arg in "${@:2}"; do
    case "$arg" in
        --cached) cached_only="--cached" ;;
        --search) search_mode=true ;;
    esac
done

BOT_STATE_FILE="/tmp/bmux-bots-state.tsv"
WORKTREE_CACHE="/tmp/bmux-worktree-cache"

# --- Bot entries (from TSV state file maintained every 2s) ---
BOT_ENTRIES=""
declare -A session_priority
if [ -f "$BOT_STATE_FILE" ] && [ -s "$BOT_STATE_FILE" ]; then
    shopt -s extglob
    NOW=$EPOCHSECONDS
    E=$'\033'
    while IFS=$'\t' read -r last_changed session_name window_id window_name pane_id pane_title _ _ state; do
        [ -z "$state" ] && continue
        elapsed=$(( NOW - last_changed ))
        if   [ "$elapsed" -lt 60 ];    then ago="${elapsed}s"
        elif [ "$elapsed" -lt 3600 ];  then ago="$(( elapsed / 60 ))m"
        elif [ "$elapsed" -lt 86400 ]; then ago="$(( elapsed / 3600 ))h"
        else ago="$(( elapsed / 86400 ))d"; fi

        pane="${pane_title##+([^a-zA-Z0-9])}"
        [ ${#pane} -gt 40 ] && pane="${pane:0:37}..."

        bot=$(cat "/tmp/bmux-bots/${pane_id}.name" 2>/dev/null)
        [ -z "$bot" ] && bot="$window_name"

        local_pri=3
        case "$state" in
            attention) BOT_ENTRIES+="bot|${pane_id}|${window_id}|${session_name}|attention"$'\t'"    ${E}[33m${ICON_ATTENTION}${E}[0m ${bot} ${pane} ${E}[90m${ago}${E}[0m"$'\n'; local_pri=0 ;;
            idle)      BOT_ENTRIES+="bot|${pane_id}|${window_id}|${session_name}|idle"$'\t'"    ${E}[32m${ICON_IDLE}${E}[0m ${E}[90m${bot} ${pane} ${ago}${E}[0m"$'\n'; local_pri=2 ;;
            *)         BOT_ENTRIES+="bot|${pane_id}|${window_id}|${session_name}|running"$'\t'"    ${E}[36m${ICON_RUNNING}${E}[0m ${bot} ${pane} ${E}[90m${ago}${E}[0m"$'\n'; local_pri=1 ;;
        esac
        cur_pri="${session_priority[$session_name]:-3}"
        [ "$local_pri" -lt "$cur_pri" ] && session_priority[$session_name]="$local_pri"
    done < "$BOT_STATE_FILE"
fi

# --- Worktree data (from cache or computed on-the-fly) ---
sessions=""
repos=""
repo_list=""
all_worktrees=""

use_cache=false
if [ "$cached_only" = "--cached" ]; then
    [ -f "$WORKTREE_CACHE" ] && use_cache=true
elif [ -f "$WORKTREE_CACHE" ]; then
    cache_age=$(( EPOCHSECONDS - $(stat -f %m "$WORKTREE_CACHE" 2>/dev/null || echo 0) ))
    [ "$cache_age" -lt 10 ] && use_cache=true
fi

if [ "$use_cache" = true ]; then
    while IFS='|' read -r type field1 field2 field3; do
        [ -z "$type" ] && continue
        if [ "$type" = "S" ]; then
            sessions+="$field1|$field2|$field3"$'\n'
            if [[ "$repo_list" != *"|$field3|"* ]]; then
                repo_list+="|$field3|"
                repos+="$field3"$'\n'
            fi
        elif [ "$type" = "W" ]; then
            all_worktrees+="$field1|$field2"$'\n'
            if [[ "$repo_list" != *"|$field2|"* ]]; then
                repo_list+="|$field2|"
                repos+="$field2"$'\n'
            fi
        fi
    done < "$WORKTREE_CACHE"
elif [ "$cached_only" != "--cached" ]; then
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
            sessions+="$sess|$root|$base_repo"$'\n'
            if [[ "$repo_list" != *"|$base_repo|"* ]]; then
                repo_list+="|$base_repo|"
                repos+="$base_repo"$'\n'
                if git -C "$base_repo" rev-parse --git-dir > /dev/null 2>&1; then
                    while IFS= read -r line; do
                        if [[ "$line" == "worktree "* ]]; then
                            all_worktrees+="${line#worktree }|$base_repo"$'\n'
                        fi
                    done < <(git -C "$base_repo" worktree list --porcelain 2>/dev/null)
                fi
            fi
        fi
    done < <(tmux list-sessions -F '#{session_name}')

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    _list_repo() {
        local dir="$1"
        git -C "$dir" rev-parse --git-dir > /dev/null 2>&1 || return
        base_repo="$dir"
        if [ -f "$dir/.git" ]; then
            common_dir=$(cd "$dir" && git rev-parse --git-common-dir 2>/dev/null)
            if [ -n "$common_dir" ]; then
                base_repo=$(cd "$dir" && cd "$common_dir/.." && pwd)
            fi
        fi
        if [[ "$repo_list" != *"|$base_repo|"* ]]; then
            repo_list+="|$base_repo|"
            repos+="$base_repo"$'\n'
            while IFS= read -r line; do
                if [[ "$line" == "worktree "* ]]; then
                    all_worktrees+="${line#worktree }|$base_repo"$'\n'
                fi
            done < <(git -C "$base_repo" worktree list --porcelain 2>/dev/null)
        fi
    }

    while IFS= read -r project_dir; do
        [ -z "$project_dir" ] && continue
        if [[ "$project_dir" == *'/*' ]]; then
            project_dir="${project_dir%/\*}"
            [ -d "$project_dir" ] || continue
            for subdir in "$project_dir"/*/; do
                [ -d "$subdir" ] || continue
                _list_repo "${subdir%/}"
            done
        else
            [ -d "$project_dir" ] || continue
            _list_repo "$project_dir"
        fi
    done < <(bash "$SCRIPT_DIR/parse-config.sh" project_dirs)
fi

# --- Output ---
current_repo=""
if [ -n "$current_session" ]; then
    while IFS='|' read -r sess root base; do
        if [ "$sess" = "$current_session" ]; then
            current_repo="$base"
            break
        fi
    done <<< "$sessions"
fi

get_bot_instances() {
    local session_name="$1"
    local ctx_repo="$2"
    local ctx_wt="$3"
    [ -z "$BOT_ENTRIES" ] && return
    local line
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        [[ "$line" != *"|${session_name}|"* ]] && continue
        if [ -n "$ctx_repo" ]; then
            printf '%s \033[34m· %s\033[0m/\033[33m%s\033[0m\n' "$line" "$ctx_repo" "$ctx_wt"
        else
            printf '%s\n' "$line"
        fi
    done <<< "$BOT_ENTRIES"
}

output_repo() {
    local repo="$1"
    local repo_name="${repo##*/}"

    [ "$search_mode" != "true" ] && printf 'header||%s||%s\t\033[34m── %s ──\033[0m\n' "$repo_name" "$repo" "$repo_name"

    if [ -n "$current_session" ] && [ "$repo" = "$current_repo" ]; then
        while IFS='|' read -r sess root base; do
            if [ "$sess" = "$current_session" ] && [ "$base" = "$repo" ]; then
                local wt_name="${root##*/}"
                [ "$root" = "$repo" ] && wt_name="main"
                if [ "$search_mode" = "true" ]; then
                    printf 'worktree|%s|%s|active|%s\t  \033[32m●\033[0m %s (\033[33m%s\033[0m) \033[34m· %s\033[0m\n' "$root" "$sess" "$repo" "$wt_name" "$sess" "$repo_name"
                    get_bot_instances "$sess" "$repo_name" "$wt_name"
                else
                    printf 'worktree|%s|%s|active|%s\t  \033[32m●\033[0m %s (\033[33m%s\033[0m)\n' "$root" "$sess" "$repo" "$wt_name" "$sess"
                    get_bot_instances "$sess"
                fi
                break
            fi
        done <<< "$sessions"
    fi

    local sorted_sessions=""
    while IFS='|' read -r sess root base; do
        [ -z "$sess" ] && continue
        [ "$sess" = "$current_session" ] && continue
        [ "$base" != "$repo" ] && continue
        local pri="${session_priority[$sess]:-3}"
        sorted_sessions+="${pri}|${sess}|${root}|${base}"$'\n'
    done <<< "$sessions"
    sorted_sessions=$(printf '%s' "$sorted_sessions" | sort -t'|' -k1,1n)

    while IFS='|' read -r _ sess root base; do
        [ -z "$sess" ] && continue
        local wt_name="${root##*/}"
        [ "$root" = "$repo" ] && wt_name="main"
        if [ "$search_mode" = "true" ]; then
            printf 'worktree|%s|%s|active|%s\t  \033[32m●\033[0m %s (\033[33m%s\033[0m) \033[34m· %s\033[0m\n' "$root" "$sess" "$repo" "$wt_name" "$sess" "$repo_name"
            get_bot_instances "$sess" "$repo_name" "$wt_name"
        else
            printf 'worktree|%s|%s|active|%s\t  \033[32m●\033[0m %s (\033[33m%s\033[0m)\n' "$root" "$sess" "$repo" "$wt_name" "$sess"
            get_bot_instances "$sess"
        fi
    done <<< "$sorted_sessions"

    while IFS='|' read -r wt_path wt_repo; do
        [ -z "$wt_path" ] && continue
        [ "$wt_repo" != "$repo" ] && continue
        [[ "$sessions" == *"|${wt_path}|"* ]] && continue
        local wt_name="${wt_path##*/}"
        [ "$wt_path" = "$repo" ] && wt_name="main"
        if [ "$search_mode" = "true" ]; then
            printf 'worktree|%s||inactive|%s\t  \033[90m○ %s\033[0m \033[34m· %s\033[0m\n' "$wt_path" "$repo" "$wt_name" "$repo_name"
        else
            printf 'worktree|%s||inactive|%s\t  \033[90m○ %s\033[0m\n' "$wt_path" "$repo" "$wt_name"
        fi
    done <<< "$all_worktrees"
}

if [ -n "$current_repo" ]; then
    output_repo "$current_repo"
fi

declare -A repo_priority
while IFS='|' read -r sess root base; do
    [ -z "$sess" ] && continue
    [ "$base" = "$current_repo" ] && continue
    sp="${session_priority[$sess]:-3}"
    rp="${repo_priority[$base]:-3}"
    [ "$sp" -lt "$rp" ] && repo_priority[$base]="$sp"
done <<< "$sessions"

sorted_repos=""
while IFS= read -r repo; do
    [ -z "$repo" ] && continue
    [ "$repo" = "$current_repo" ] && continue
    rp="${repo_priority[$repo]:-3}"
    sorted_repos+="${rp}|${repo}"$'\n'
done <<< "$repos"
sorted_repos=$(printf '%s' "$sorted_repos" | sort -t'|' -k1,1n)

while IFS='|' read -r _ repo; do
    [ -z "$repo" ] && continue
    output_repo "$repo"
done <<< "$sorted_repos"
