#!/bin/sh
set -e

cmd="git status --short $@"
if [ "$($cmd 2>&1)" ]; then
    $cmd
    exit 1
fi

cmd="git status --short --branch $@"
if $cmd |grep -q 'behing'; then
    $cmd
    exit 1
fi

current_branch="$(_git-current-branch)"
#closest_branch="$(git log --pretty="format:%D" |grep -v "^HEAD ->" |grep -v "^$" |tr , \\n |sed -r 's/^ //' |grep -v "^tag:" |head -n1)"
pr_id="$(gh pr list --head "$current_branch" |grep '.*' |sed -r 's/^([0-9]+)[^0-9].*$/\1/g')"
if [ "$pr_id" ]; then
    base_branch="$(gh pr view $pr_id --json baseRefName --jq '.baseRefName')"
    if git branch --verbose |egrep -q "^ +$base_branch +[0-9a-f]+ +\[behind [0-9]+\]"; then
        echo "base branch '$base_branch' needs to be updated"
        exit 1
    fi

    last_commit="$(git show-ref --heads -s $base_branch)"
    common_commit="$(git merge-base $base_branch $current_branch)"
    if [ "$last_commit" != "$common_commit" ]; then
        echo "rebase/merge on base_branch '$base_branch' is required"
        exit 1
    fi
fi

cmd="git status --short --branch $@"
if $cmd |grep -q 'ahead'; then
    $cmd
    exit 1
fi

#env printf '\xF0\x9F\x91\x8D\n'
echo "👍"
