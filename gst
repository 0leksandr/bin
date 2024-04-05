#!/bin/sh
set -e
args=$*

arg_all=""
if [ "$args" = "--all" ]; then
    args=""
    arg_all=1
fi

ok=1
err() {
    eval "$@"
    ok=""
}

cmd="git status --short $args"
if [ "$($cmd 2>&1)" ]; then
    err "$cmd"
fi

has_remote=""
if [ "$(git remote show)" != "" ]; then
    has_remote="1"
fi

if [ "$has_remote" ]; then
    filename=".git/FETCH_HEAD"
    case "$(uname)" in
        Linux)  fetched_at="$(stat --format=%Y "$filename")" ;;
        Darwin) fetched_at="$(stat -f %m "$filename")"       ;;
        *)      err echo "unknown operating system"          ;;
    esac
    fetched_ago=$(($(date +%s) - fetched_at))
    if [ $fetched_ago -gt 60 ]; then
        git fetch --quiet
    fi
fi

cmd="git status --short --branch $args"
if $cmd |grep -Eq ' \[(ahead [0-9]+, )?behind [0-9]+\]$'; then
    err "$cmd"
fi

if [ "$has_remote" ]; then
    reg="^ +([^ ]+) +[0-9a-f]+ +\[behind [0-9]+\].*$"
    for base_branch in $(git branch --verbose |grep -E "$reg" |sed -r "s/$reg/\1/g"); do
        err echo "base branch \"$base_branch\" needs to be updated"
    done
fi

if [ "$has_remote" ]; then
    branches=""
    all_branches="$(git branch --list |sed -r "s/^\\*? +//")"
    if [ "$arg_all" ]; then
        #default_branch="$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
        branches="$all_branches"
    else
        branches="$(_git-current-branch)"
    fi

    for branch in $branches; do
        closest_branches="$(                       \
            git log --pretty="format:%D" "$branch" \
                |grep --invert-match "^$"          \
                |tr , \\n                          \
                |sed -r "s/^ //"                   \
                |grep --invert-match "^HEAD ->"    \
                |grep --invert-match "^tag:"       \
                |grep --invert-match "^origin/"    \
            ||:                                    \
        )"
        branches="$branches\n$closest_branches"
    done
    branches="$(echo "$branches" |grep --invert-match "^$" |sort --unique)"

    if [ "$branches" ]; then
        for branch in $branches; do
            for remote_base_branch in $(gh pr list --head "$branch" --json baseRefName --jq '.[].baseRefName'); do
                if echo "$all_branches" |grep -Eq "^$remote_base_branch$"; then
                    last_commit="$(git show-ref --heads -s "$remote_base_branch")"
                    common_commit="$(git merge-base "$branch" "$remote_base_branch")"
                    if [ "$last_commit" != "$common_commit" ]; then
                        err echo "rebase/merge of \"$branch\" on base_branch \"$remote_base_branch\" is required"
                    fi
                else
                    err echo "remote base branch \"$remote_base_branch\" not found locally"
                fi
            done
        done
    fi
fi

cmd="git status --short --branch $args"
if $cmd |grep -Eq ' \[ahead [0-9]+\]$'; then
    err "$cmd"
fi

if [ "$ok" ]; then
    #env printf '\xF0\x9F\x91\x8D\n'
    echo "👍"
else
    exit 1
fi
