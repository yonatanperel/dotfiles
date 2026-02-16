#!/bin/bash
DIR="$1"
CUR="$2"
ENTRIES="$3"
MODE_FILE="$4"

if [ "$(cat "$MODE_FILE" 2>/dev/null)" = "search" ]; then
    if [ "$DIR" = "next" ]; then
        echo "down+transform(echo {} | cut -f1 | grep -q '^header' && echo down)"
    else
        echo "up+transform(echo {} | cut -f1 | grep -q '^header' && { [ {n} -eq 0 ] && echo down || echo up; })"
    fi
    exit 0
fi

if [ "$DIR" = "next" ]; then
    awk -F'\t' -v cur="$CUR" 'NR > cur+1 { split($1,a,"|"); if(a[1]=="worktree"){print "pos("NR")"; exit} }' "$ENTRIES"
else
    awk -F'\t' -v cur="$CUR" 'NR <= cur { split($1,a,"|"); if(a[1]=="worktree") last=NR } END { if(last) print "pos("last")" }' "$ENTRIES"
fi
