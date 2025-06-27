#!/bin/sh
set -e
dir="$1"

repo="$(git -C "$dir" remote get-url origin | sed -E 's|.*github.com[/:]([^/]+/[^/]*)(\.git)?$|\1|')"
default_branch="$(gh --repo "$repo" repo view --json defaultBranchRef --jq '.defaultBranchRef.name')"
#default_branch="$(git -C "$dir" rev-parse --abbrev-ref origin/HEAD 2>/dev/null)"

git -C "$dir" --no-pager branch --list | sed -r "s/^\\*? +//" | while read -r branch; do
    if [ "$branch" != "$default_branch" ]; then
        printf "%s: " "$branch"
        #status="$(GH_PAGER="" gh --repo "$repo" pr list --head "$branch" --state all --json state -q '.[].state')"
        status="$(gh --repo "$repo" pr list --head "$branch" --state all --json state -q '.[].state')"
        echo "status[$status]"
        if echo "$status" |grep -Eq "^(CLOSED|MERGED)?$"; then
            echo "❌"
        else
            echo "✅"
        fi
        printf "\n"
    fi
done
