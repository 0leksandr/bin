#!/bin/sh
set -e
ok=1
err() {
    $@
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
        git fetch --quiet
    fi
fi

cmd="git status --short --branch $@"
if $cmd |egrep -q ' \[(ahead [0-9]+, )?behind [0-9]+\]$'; then
    err $cmd
fi

current_branch="$(_git-current-branch)"
base_branches="$(gh pr list --head "$current_branch" --json baseRefName --jq '.[].baseRefName')"
if [ ! "$base_branches" ]; then
    closest_branch="$(git log --pretty="format:%D" |grep -v "^HEAD ->" |grep -v "^$" |tr , \\n |sed -r "s/^ //" |grep -v "^tag:" |grep -v "^origin/" |head --lines=1)"
    base_branches="$closest_branch"

    ##reg="^HEAD -> $current_branch, ((?:\\w|[-/])+)$"
    #reg="^HEAD -> $current_branch, ([^ ]+)$"
    #line="$(git log --pretty="format:%D" |egrep "$reg" |head --lines=1 ||:)"
    #if [ "$line" ]; then
    #    reg="$(echo "$reg" |sed -r "s / \\\\/ g")"
    #    base_branch="$(echo "$line" |sed -r "s/$reg/\1/")"
    #fi
fi
if [ "$base_branches" ]; then
    for base_branch in $base_branches; do
        if git branch --verbose |egrep -q "^ +$base_branch +[0-9a-f]+ +\[behind [0-9]+\]"; then
            err echo "base branch '$base_branch' needs to be updated"
        fi

        last_commit="$(git show-ref --heads -s $base_branch)"
        common_commit="$(git merge-base $base_branch $current_branch)"
        if [ "$last_commit" != "$common_commit" ]; then
            err echo "rebase/merge on base_branch '$base_branch' is required"
        fi
    done
fi

cmd="git status --short --branch $@"
if $cmd |egrep -q ' \[ahead [0-9]+\]$'; then
    err $cmd
fi

if [ "$ok" ]; then
    #env printf '\xF0\x9F\x91\x8D\n'
    echo "👍"
else
    exit 1
fi
