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
linear_team=""
linear_in_progress_status=""
while IFS=$'\t' read -r key val; do
    case "$key" in
        api_key) linear_api_key=$(_resolve "$val") ;;
        team) linear_team=$(_resolve "$val") ;;
        in_progress_status) linear_in_progress_status=$(_resolve "$val") ;;
    esac
done < <(bash "$SCRIPT_DIR/parse-config.sh" linear "$main_repo")

# --- Linear API functions ---

linear_get_issues() {
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: $linear_api_key" \
        --data '{ "query": "{ issues(filter: {and: {assignee: {isMe: {eq: true}}}, state: {type: {in: [\"started\", \"unstarted\"]}}}) { nodes { id branchName title } } }" }' \
        https://api.linear.app/graphql
}

linear_get_team_id() {
    local team_name="$1"
    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: $linear_api_key" \
        --data '{ "query": "{ teams { nodes { id name } } }" }' \
        https://api.linear.app/graphql)
    echo "$response" | jq -r ".data.teams.nodes[] | select(.name == \"$team_name\") | .id"
}

linear_get_current_user_id() {
    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: $linear_api_key" \
        --data '{ "query": "{ viewer { id } }" }' \
        https://api.linear.app/graphql)
    echo "$response" | jq -r '.data.viewer.id'
}

linear_create_ticket() {
    local title="$1"
    local team_id
    team_id=$(linear_get_team_id "$linear_team")
    local user_id
    user_id=$(linear_get_current_user_id)

    if [ -z "$team_id" ] || [ "$team_id" = "null" ]; then
        echo "Error: Failed to find team ID for: $linear_team" >&2
        return 1
    fi
    if [ -z "$user_id" ] || [ "$user_id" = "null" ]; then
        echo "Error: Failed to get current user ID" >&2
        return 1
    fi

    local query
    query=$(jq -n \
        --arg title "$title" \
        --arg team "$team_id" \
        --arg user "$user_id" \
        '{query: "mutation { issueCreate(input: { title: \($title | @json), teamId: \($team | @json), assigneeId: \($user | @json) }) { issue { id branchName } } }"}')

    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: $linear_api_key" \
        --data "$query" \
        https://api.linear.app/graphql
}

linear_set_in_progress() {
    local issue_id="$1"
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: $linear_api_key" \
        --data '{ "query": "mutation { issueUpdate(id: \"'"$issue_id"'\", input: { stateId: \"'"$linear_in_progress_status"'\" }) { issue { state { id } } } }" }' \
        https://api.linear.app/graphql > /dev/null
}

# --- Branch selection ---

branch_name=""
issue_id=""
is_new_ticket=false

if [ -n "$linear_api_key" ]; then
    echo "Fetching Linear tickets..."
    issues_response=$(linear_get_issues)

    if echo "$issues_response" | jq -e '.errors' > /dev/null 2>&1; then
        echo "Error fetching tickets:"
        echo "$issues_response" | jq -r '.errors[].message'
        exit 1
    fi

    ticket_lines=$(echo "$issues_response" | jq -r '.data.issues.nodes[] | "\(.branchName) - \(.title)"')

    if [ -z "$ticket_lines" ]; then
        echo "No assigned tickets found."
        echo ""
        echo "Enter a title for a new ticket (or Ctrl-C to cancel):"
        read -r title
        if [ -z "$title" ]; then
            echo "No title provided. Exiting."
            exit 1
        fi
        echo "Creating ticket: $title"
        create_response=$(linear_create_ticket "$title")
        branch_name=$(echo "$create_response" | jq -r '.data.issueCreate.issue.branchName')
        issue_id=$(echo "$create_response" | jq -r '.data.issueCreate.issue.id')
        is_new_ticket=true
    else
        selection=$(echo "$ticket_lines" | fzf --print-query --prompt="Select ticket or type new title: " --header="Arrow keys to select, type to create new ticket" || true)

        query_line=$(echo "$selection" | head -n 1)
        selected_line=$(echo "$selection" | tail -n 1)

        if [ -z "$selection" ]; then
            echo "Cancelled."
            exit 0
        fi

        if [ "$query_line" = "$selected_line" ] && ! echo "$ticket_lines" | grep -qxF "$selected_line"; then
            echo "Creating new ticket: $query_line"
            create_response=$(linear_create_ticket "$query_line")
            if echo "$create_response" | jq -e '.errors' > /dev/null 2>&1; then
                echo "Error creating ticket:"
                echo "$create_response" | jq -r '.errors[].message'
                exit 1
            fi
            branch_name=$(echo "$create_response" | jq -r '.data.issueCreate.issue.branchName')
            issue_id=$(echo "$create_response" | jq -r '.data.issueCreate.issue.id')
            is_new_ticket=true
        else
            branch_name=$(echo "$selected_line" | cut -d' ' -f1)
            issue_id=$(echo "$issues_response" | jq -r ".data.issues.nodes[] | select(.branchName == \"$branch_name\") | .id")
        fi
    fi
else
    echo "Enter branch name (or Ctrl-C to cancel):"
    read -r branch_name
fi

if [ -z "$branch_name" ]; then
    echo "No branch name. Exiting."
    exit 1
fi

echo ""
echo "Branch: $branch_name"

# --- Read worktree config ---

worktree_dir=$(bash "$SCRIPT_DIR/parse-config.sh" worktree_dir "$main_repo")
[ -z "$worktree_dir" ] && worktree_dir="../worktrees"

# Resolve worktree_dir relative to main repo
if [[ "$worktree_dir" != /* ]]; then
    worktree_base="$main_repo/$worktree_dir"
else
    worktree_base="$worktree_dir"
fi
worktree_base=$(cd "$(dirname "$worktree_base")" 2>/dev/null && echo "$(pwd)/$(basename "$worktree_base")" || echo "$worktree_base")

worktree_path="$worktree_base/$branch_name"

# --- Create worktree ---

mkdir -p "$worktree_base"

default_branch="master"
if git show-ref --verify --quiet "refs/heads/main"; then
    default_branch="main"
fi

branch_existed=false
if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    branch_existed=true
fi

if git worktree list | grep -q "^$worktree_path "; then
    echo "Worktree already exists at $worktree_path"
else
    echo "Creating worktree..."
    if [ "$branch_existed" = true ]; then
        git worktree add "$worktree_path" "$branch_name"
    else
        git worktree add -b "$branch_name" "$worktree_path" "$default_branch"
    fi
fi

# --- Create symlinks ---

while IFS= read -r rel_path; do
    [ -z "$rel_path" ] && continue
    src="$main_repo/$rel_path"
    dst="$worktree_path/$rel_path"
    if [ -e "$src" ] && [ ! -e "$dst" ]; then
        mkdir -p "$(dirname "$dst")"
        ln -s "$src" "$dst"
        echo "  Symlinked $rel_path"
    fi
done < <(bash "$SCRIPT_DIR/parse-config.sh" worktree_symlinks "$main_repo")

# --- Create copies ---

while IFS= read -r rel_path; do
    [ -z "$rel_path" ] && continue
    src="$main_repo/$rel_path"
    dst="$worktree_path/$rel_path"
    if [ -e "$src" ] && [ ! -e "$dst" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -r "$src" "$dst"
        echo "  Copied $rel_path"
    fi
done < <(bash "$SCRIPT_DIR/parse-config.sh" worktree_copies "$main_repo")

# --- Set ticket to in progress ---

if [ -n "$issue_id" ] && [ "$issue_id" != "null" ] && [ "$branch_existed" = false ] && [ -n "$linear_in_progress_status" ]; then
    echo "Setting ticket to in progress..."
    linear_set_in_progress "$issue_id"
fi

# --- Create tmux session ---

echo ""
echo "Creating session..."
bash "$SCRIPT_DIR/create-session.sh" "$worktree_path"
