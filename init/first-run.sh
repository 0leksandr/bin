#!/bin/sh
set -e

mkdir -p "$HOME/.temp"
touch "$HOME/.temp/history"

if [ "$(../_os)" = "mac" ]; then
  is_mac="1"
else
  is_mac=""
fi

if [ "$is_mac" ]; then
  brew install bash-completion@2
  [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
fi

rc="$(dirname "$0")/../rc"
"$(dirname "$0")/../utils/register-in-profile.sh" "$rc/profile" "profile"
"$(dirname "$0")/../utils/register-in-profile.sh" "$rc/rc" "rc"
# sudo sh -c "echo \"\\n. $(realpath ./rc/profile_root)\" >> /etc/environment"

read -p "GitHub name: " gh_name
read -p "GitHub email: " gh_email
git config --global user.name "${gh_name}"
git config --global user.email "${gh_email}"
# https://stackoverflow.com/questions/1899792/why-is-git-submodule-not-updated-automatically-on-git-checkout
git config --global submodule.recurse true
git config --global core.editor "nano"

if [ "$is_mac" ]; then
  brew install gh
fi
gh auth login

printf '/.idea/\n/.venv/\n/__pycache__/\n' > "$HOME/.gitignore"
git config --global core.excludesFile "$HOME/.gitignore"

#if [ "$is_mac" ]; then
#    :
#    # https://support.codeweavers.com/Remap%20the%20Option%20key%20to%20be%20the%20Alt%20key#:~:text=For%20manual%20reference%20the%20registry,from%20Windows%20Applications%20using%20PDFwriter
#    # "LeftCommandIsCtrl"="Y"
#    # "RightCommandIsCtrl"="Y"
#fi
