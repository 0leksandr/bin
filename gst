#!/bin/sh
set -e
args=$*

arg_all=""
if [ "$args" = "-a" ]; then
    args=""
    arg_all=1
fi

ok=1
err() {
    [ "$ok" ] || echo ""
    eval "$@"
    ok=""
}

check_reg() {
    cmd="$1"
    reg="$2"

    out="$(git $cmd |grep --line-number -E "$reg" ||:)"
    if [ "$out" ]; then
        err echo "'$(                                    \
            git -c color.status=always $cmd              \
                |sed -n "$(                              \
                    echo "$out"                          \
                        |sed -r 's/^([0-9]+):.*$/\1p;/g' \
                        |tr -d '\n'                      \
                )"                                       \
                |sed "s/'/'\"'\"'/g"                     \
        )'"
    fi
}

clear_line() {
    printf "\r"
    printf '%*s' "${COLUMNS:-$(tput cols)}"
    printf "\r"
}

git status >/dev/null  # exit and print info if not in git repository

check_reg "status --short $args" '.*'

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
        printf "fetching..."
        git fetch --quiet
        clear_line
    fi
fi

check_reg "status --short --branch $args" ' \[(ahead [0-9]+, )?behind [0-9]+\]$'

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
                |sed -r "s/^ //g"                  \
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
            printf "querying PRs for branch $branch..."
            remote_base_branches="$(gh pr list --head "$branch" --json baseRefName --jq '.[].baseRefName')"
            clear_line
            for remote_base_branch in $remote_base_branches; do
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

check_reg "status --short --branch $args" ' \[ahead [0-9]+\]$'

if [ "$ok" ]; then
    #env printf '\xF0\x9F\x91\x8D\n'
    echo "👍"
else
    exit 1
fi
