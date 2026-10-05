#!/bin/sh
set -eu

# Setup:   $0 <directory> <email> [GitLab / GitHub Enterprise / github.com host]
# Cleanup: $0 <directory> [--direnv]
#          (--direnv also removes the shell hook, all direnv config/data/cache and uninstalls direnv)
#
# Examples:
#   $0 ~/work/ me@company.com                  (no gh/glab setup)
#   $0 ~/work/ me@company.com git.company.com  (self-hosted GitLab or GHE)
#   $0 ~/work/ me@company.com github.com       (separate work account on github.com)
#   $0 ~/work/                                 (cleanup)
#   $0 ~/work/ --direnv                        (cleanup + remove direnv completely)
target="${1:?Specify a directory (usage: $0 <directory> <email> [host])}"
arg2="${2:-}"
remove_direnv=0

# Read a secret from the terminal without echo (works even if stdin is not a tty)
read_token() {
    printf '%s' "$1" > /dev/tty
    stty -echo < /dev/tty
    read -r token < /dev/tty
    stty echo < /dev/tty
    printf '\n' > /dev/tty
}

wait_enter() {
    printf 'Press Enter when done... ' > /dev/tty
    read -r _ < /dev/tty
}

# Print the primary key fingerprint of the secret key whose UID matches this email
# $1 = email
gpg_fingerprint() {
    gpg --list-secret-keys --with-colons "<$1>" 2>/dev/null | awk -F: '/^fpr:/{print $10; exit}'
}

# ---- Claude Code / direnv definitions ----

# direnv config directory (used by both setup and cleanup)
direnv_conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/direnv"

# Append the direnv hook to an rc file unless an uncommented hook line is already there
# $1 = rc file, $2 = hook line
add_direnv_hook() {
    mkdir -p "$(dirname "$1")"
    if ! grep -q '^[^#]*direnv hook' "$1" 2>/dev/null; then
        printf '\n# direnv\n%s\n' "$2" >> "$1"
        echo "Added direnv hook to $1, open a new terminal to activate it" >&2
    fi
}

# Remove the hook lines written by add_direnv_hook (exact-line match, other lines untouched)
# $1 = rc file
remove_direnv_hook() {
    [ -f "$1" ] || return 0
    tmp=$(mktemp)
    grep -vxF \
        -e '# direnv' \
        -e 'eval "$(direnv hook zsh)"' \
        -e 'eval "$(direnv hook bash)"' \
        "$1" > "$tmp" ||:   # grep exits 1 when no lines are left
    cat "$tmp" > "$1"       # cat instead of mv, keeps symlinked dotfiles intact
    rm -f "$tmp"
}

# ---- end Claude Code / direnv definitions ----

cleanup() {
    [ -d "$target" ] || { echo "Directory $target does not exist" >&2; exit 1; }
    dirname=$(cd "$target" && pwd -P)
    case "$dirname" in
        /|"$HOME") echo "Refusing to delete $dirname" >&2; exit 1 ;;
    esac

    printf 'This will delete %s including all clones. Check for unpushed changes. Continue? [y/N] ' "$dirname"
    read -r answer
    [ "$answer" = y ] || exit 1

    # Remove the key from ssh-agent (if it was added)
    ssh-add -d "$dirname/.ssh/id_work" 2>/dev/null ||:

    # Stop the dedicated gpg-agent; the key itself is deleted together with the directory
    gpgconf --homedir "$dirname/.gnupg" --kill gpg-agent 2>/dev/null ||:

    # Remove the includeIf entry from the global git config
    git config --global --remove-section "includeIf.gitdir:$dirname/" 2>/dev/null ||:

    rm -rf "$dirname"

    if [ "$remove_direnv" = 1 ]; then
        direnv_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/direnv"
        direnv_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/direnv"
        remove_direnv_hook "$HOME/.zshrc"
        remove_direnv_hook "$HOME/.bashrc"
        rm -rf "$direnv_conf_dir" "$direnv_data_dir" "$direnv_cache_dir"
        if command -v direnv >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
            brew uninstall direnv || echo "brew uninstall direnv failed" >&2
        fi
        echo "direnv removed, open a new terminal to deactivate the hook"
    fi

    cat <<EOF
Done. Left to do manually:
  - delete the SSH key on GitHub/GitLab (Settings -> SSH keys)
  - delete the GPG key on GitHub/GitLab (Settings -> GPG keys)
  - revoke the personal access token created for glab/gh
  - optionally delete the id_work entry in Keychain Access
  - delete the 'Claude Code-credentials-*' entry for this directory in Keychain Access (macOS)
EOF
}

setup() {
    email="$arg2"
    host="${3:-}"
    # Normalize host: strip scheme and trailing slash
    host="${host#*://}"
    host="${host%/}"
    mkdir -p "$target"
    dirname=$(cd "$target" && pwd -P)

    # Detect the host type (only if a host was given)
    forge=""
    if [ -n "$host" ]; then
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://$host/api/v4/version" ||:)
        case "$code" in
            000|"") echo "Host $host is unreachable" >&2; exit 1 ;;
            200|401) forge=gitlab ;;
            *) forge=github ;;
        esac
    fi

    # SSH key (not regenerated if it already exists)
    mkdir -p "$dirname/.ssh"
    chmod 700 "$dirname/.ssh"
    if [ ! -f "$dirname/.ssh/id_work" ]; then
        echo "Generating the SSH key, you will be asked to choose a passphrase" >&2
        ssh-keygen -t ed25519 -C "$email" -f "$dirname/.ssh/id_work"
    fi

    # Work git config (included from the global config via includeIf)
    cat > "$dirname/.gitconfig" <<EOF
[user]
    email = $email
[core]
    sshCommand = ssh -i $dirname/.ssh/id_work -o IdentitiesOnly=yes -o UserKnownHostsFile=$dirname/.ssh/known_hosts
EOF

    # GPG: separate home inside the directory; git calls gpg without GNUPGHOME,
    # so gpg.program points to a wrapper that sets it
    mkdir -p "$dirname/.gnupg"
    chmod 700 "$dirname/.gnupg"
    export GNUPGHOME="$dirname/.gnupg"
    cat > "$dirname/.gnupg/gpg-wrapper" <<EOF
#!/bin/sh
GNUPGHOME="$dirname/.gnupg" exec gpg "\$@"
EOF
    chmod +x "$dirname/.gnupg/gpg-wrapper"

    GPG_TTY="/dev/$(ps -o tty= -p $$ | tr -d ' ')"
    export GPG_TTY
    gpg_key=$(gpg_fingerprint "$email")
    if [ -z "$gpg_key" ]; then
        name="$(git config --global --get user.name)"
        echo "Generating the GPG key for $email, you will be asked to choose a passphrase" >&2
        gpg --quick-generate-key "$name <$email>" ed25519 sign never
        gpg_key=$(gpg_fingerprint "$email")
    fi
    git config -f "$dirname/.gitconfig" user.signingkey "$gpg_key"
    git config -f "$dirname/.gitconfig" gpg.program "$dirname/.gnupg/gpg-wrapper"

    # Service repository: ignore everything, forbid commits
    git init -q -b work "$dirname" 2>/dev/null
    git -C "$dirname" symbolic-ref HEAD refs/heads/work
    grep -qxF '*' "$dirname/.git/info/exclude" 2>/dev/null || echo '*' >> "$dirname/.git/info/exclude"
    cat > "$dirname/.git/hooks/pre-commit" <<'EOF'
#!/bin/sh
echo "Service repo, commits disabled" >&2
exit 1
EOF
    chmod +x "$dirname/.git/hooks/pre-commit"

    # gh/glab: separate config inside the directory + login (only if a host was given)
    if [ -n "$host" ]; then
        mkdir -p "$dirname/.config"
        chmod 700 "$dirname/.config"

        if [ "$forge" = gitlab ]; then
            mkdir -p "$dirname/.config/glab-cli"
            git config -f "$dirname/.gitconfig" my.forge glab
            git config -f "$dirname/.gitconfig" my.configDir "$dirname/.config/glab-cli"
            cat >&2 <<EOF
glab login: create a personal access token with the 'api' scope at
https://$host/-/user_settings/personal_access_tokens, then paste it below.
EOF
            read_token "GitLab token (scope api): "
            printf '%s' "$token" | GLAB_CONFIG_DIR="$dirname/.config/glab-cli" glab auth login --hostname "$host" --stdin
            unset token
        else
            mkdir -p "$dirname/.config/gh"
            git config -f "$dirname/.gitconfig" my.forge gh
            git config -f "$dirname/.gitconfig" my.configDir "$dirname/.config/gh"
            cat >&2 <<EOF
gh login: create a personal access token with the 'repo' and 'read:org' scopes at
https://$host/settings/tokens, then paste it below.
EOF
            read_token "GitHub token (scopes repo, read:org): "
            printf '%s' "$token" | GH_CONFIG_DIR="$dirname/.config/gh" gh auth login --hostname "$host" --insecure-storage -p ssh --with-token
            unset token
        fi
    fi

    # Global git config entry (outside the directory)
    git config --global "includeIf.gitdir:$dirname/.path" "$dirname/.gitconfig"

    # Public SSH key: the user must upload it to the work account
    cat <<EOF

=== ACTION REQUIRED: add this SSH key to your work account ===
It lets git clone/push over SSH. Without it, cloning work repositories will fail.
  GitHub: Settings -> SSH and GPG keys -> New SSH key (type: Authentication Key)
  GitLab: Preferences -> SSH Keys
Paste the whole line below:

EOF
    cat "$dirname/.ssh/id_work.pub"
    echo
    wait_enter

    # Public GPG key: the user must upload it to the work account
    cat <<EOF

=== ACTION REQUIRED: add this GPG key to your work account ===
It makes your signed commits show as 'Verified'. $email must be a verified email
on the work account, otherwise the commits stay 'Unverified'.
  GitHub: Settings -> SSH and GPG keys -> New GPG key
  GitLab: Preferences -> GPG Keys
Paste the whole block below, including the BEGIN and END lines:

EOF
    gpg --armor --export "$gpg_key"
    echo
    wait_enter

    # ---- Claude Code / direnv ----
    # Claude Code: separate config dir for the work account, selected by direnv
    envrc="$dirname/.envrc"
    line="export CLAUDE_CONFIG_DIR=\"$dirname/.config/claude\""
    grep -qxF "$line" "$envrc" 2>/dev/null || echo "$line" >> "$envrc"
    # Install direnv via Homebrew if missing
    if ! command -v direnv >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install direnv || echo "brew install direnv failed" >&2
        else
            echo "direnv is missing and Homebrew was not found, install direnv manually" >&2
        fi
    fi
    if command -v direnv >/dev/null 2>&1; then
        direnv allow "$dirname"
    fi
    # Quiet direnv output: hide env diff and "unloading", silence status messages, keep errors
    # (existing files are never overwritten)
    mkdir -p "$direnv_conf_dir"
    [ -f "$direnv_conf_dir/direnv.toml" ] || printf '[global]\nhide_env_diff = true\nlog_filter = "unloading"\n' > "$direnv_conf_dir/direnv.toml"
    [ -f "$direnv_conf_dir/direnvrc" ] || printf '# Silence status messages, keep errors\nlog_status() { :; }\n' > "$direnv_conf_dir/direnvrc"
    # Enable the direnv shell hook (idempotent)
    # Note: on macOS, login bash shells read ~/.bash_profile instead of ~/.bashrc
    case "${SHELL:-}" in
        */zsh|*/bash)
            sh_name="${SHELL##*/}"
            add_direnv_hook "$HOME/.${sh_name}rc" "eval \"\$(direnv hook $sh_name)\""
            ;;
        *) echo "Unsupported shell '${SHELL:-}', add the direnv hook manually" >&2 ;;
    esac
    cat >&2 <<EOF
=== NEXT STEP: Claude Code ===
Open a new terminal, cd into $dirname, run 'claude' and log in with the work account.
EOF
    # ---- end Claude Code / direnv ----
}

case "$arg2" in
    "") cleanup ;;
    --direnv) remove_direnv=1; cleanup ;;
    -*) echo "Unknown option: $arg2" >&2; exit 1 ;;
    *) setup "$@" ;;
esac
