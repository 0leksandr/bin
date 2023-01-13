#!/bin/sh
set -e
ok=1
function err() {
    $@ >&2
    ok=""
}

cmd="git status --short $@"
if [ "$($cmd 2>&1)" ]; then
    err $cmd
fi

if [ "$(gh pr list)" ]; then
    fetched_ago=$(($(date +%s) - $(stat -f %m .git/FETCH_HEAD)))
    if [ $fetched_ago -gt 60 ]; then
        #err echo "last fetch was $fetched_ago seconds ago"
        git fetch
    fi
fi

cmd="git status --short --branch $@"
if $cmd |egrep -q ' \[(ahead \d+, )?behind \d+\]$'; then
    err $cmd
fi

current_branch="$(_git-current-branch)"
#closest_branch="$(git log --pretty="format:%D" |grep -v "^HEAD ->" |grep -v "^$" |tr , \\n |sed -r 's/^ //' |grep -v "^tag:" |head -n1)"
pr_id="$(gh pr list --head "$current_branch" |grep '.*' |sed -r 's/^([0-9]+)[^0-9].*$/\1/g')"
if [ "$pr_id" ]; then
    base_branch="$(gh pr view $pr_id --json baseRefName --jq '.baseRefName')"
    if git branch --verbose |egrep -q "^ +$base_branch +[0-9a-f]+ +\[behind [0-9]+\]"; then
        err echo "base branch '$base_branch' needs to be updated"
    fi

    last_commit="$(git show-ref --heads -s $base_branch)"
    common_commit="$(git merge-base $base_branch $current_branch)"
    if [ "$last_commit" != "$common_commit" ]; then
        err echo "rebase/merge on base_branch '$base_branch' is required"
    fi
fi

cmd="git status --short --branch $@"
if $cmd |egrep -q ' \[ahead \d+\]$'; then
    err $cmd
fi

if [ "$ok" ]; then
    #env printf '\xF0\x9F\x91\x8D\n'
    echo "👍"
else
    exit 1
fi
