#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "$1" ] && [ -d "$1" ]; then
    main_repo="$1"
else
    session=$(tmux display-message -p '#S')
    session_root_dir=$(tmux show-environment -t "$session" SESSION_ROOT_DIR 2>/dev/null | cut -d= -f2-)

    if [ -z "$session_root_dir" ] || [ ! -d "$session_root_dir" ]; then
        echo "Error: SESSION_ROOT_DIR not set or invalid for session '$session'"
        exit 1
    fi

    cd "$session_root_dir"

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not a git repository: $session_root_dir"
        exit 1
    fi

    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    if [[ "$git_common_dir" != /* ]]; then
        git_common_dir="$(pwd)/$git_common_dir"
    fi
    branch=$(git rev-parse --abbrev-ref HEAD)
    main_repo=$(cd "$(dirname "$git_common_dir")" && pwd)
fi
cd "$main_repo"

while IFS= read -r env_file; do
    [ -z "$env_file" ] && continue
    if [ -f "$main_repo/$env_file" ]; then
        set -a
        source "$main_repo/$env_file"
        set +a
    fi
done < <(bash "$SCRIPT_DIR/parse-config.sh" env "$main_repo")

_resolve() {
    local val="$1"
    if [[ "$val" == \$* ]]; then
        local var="${val#\$}"
        echo "${!var:-}"
    else
        echo "$val"
    fi
}

linear_api_key=""
while IFS=$'\t' read -r key val; do
    case "$key" in
        api_key) linear_api_key=$(_resolve "$val") ;;
    esac
done < <(bash "$SCRIPT_DIR/parse-config.sh" linear "$main_repo")

if [ -z "$linear_api_key" ]; then
    echo "No Linear config found for this project."
    exit 1
fi

if [ -z "$branch" ]; then
    branch=$(git rev-parse --abbrev-ref HEAD)
fi

if [ "$branch" = "HEAD" ] || [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    echo "Current branch '$branch' is not a ticket branch."
    exit 1
fi

response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: $linear_api_key" \
    --data '{ "query": "{ issues(filter: {assignee: {isMe: {eq: true}}}) { nodes { branchName identifier title description url } } }" }' \
    https://api.linear.app/graphql)

if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error from Linear API:"
    echo "$response" | jq -r '.errors[].message'
    exit 1
fi

node=$(echo "$response" | jq --arg branch "$branch" '.data.issues.nodes[] | select(.branchName == $branch)' | jq -s '.[0]')

if [ -z "$node" ] || [ "$node" = "null" ]; then
    echo "No Linear ticket found for branch '$branch'."
    exit 1
fi

identifier=$(echo "$node" | jq -r '.identifier')
title=$(echo "$node" | jq -r '.title')
url=$(echo "$node" | jq -r '.url')
description=$(echo "$node" | jq -r '.description // "No description"')

echo "$identifier: $title"
echo "$url"
echo ""
echo "$description"
