#!/bin/sh
set -eu

# Setup:   $0 <directory> <email> [GitLab / GitHub Enterprise / github.com host]
# Re-run:  $0 <directory>
#          (repeats the setup with the email and host of the first run: the email from the
#          work .gitconfig, the host from the glab/gh login; safe to run any time)
# Cleanup: $0 <directory> --delete [--direnv]
#          (--direnv also removes the shell hook, all direnv config/data/cache and uninstalls direnv)
#
# Examples:
#   $0 ~/work/ me@company.com                  (no gh/glab setup)
#   $0 ~/work/ me@company.com git.company.com  (self-hosted GitLab or GHE)
#   $0 ~/work/ me@company.com github.com       (separate work account on github.com)
#   $0 ~/work/                                 (re-run the setup)
#   $0 ~/work/ --delete                        (cleanup)
#   $0 ~/work/ --delete --direnv               (cleanup + remove direnv completely)
#
# Design: everything is automated, the setup needs no manual changes and must get none.
# Keys, logins (glab/gh), the email, the host and the config entries written here
# are changed only by this script, so it does not handle hand-made changes to them
# (another glab/gh login, an edited email, a deleted config file, a different host on a re-run).
# Existing values are kept, never overwritten, on a re-run.
# The shared .gitignore is only created empty: its ignore rules are not written by this script.
if [ $# -eq 0 ]; then
    echo "Specify a directory, usage: $0 <directory> [<email> [host] | --delete [--direnv]]" >&2
    exit 1
fi
target="$1"
arg2="${2:-}"
arg3="${3:-}"
remove_direnv=0

# Read a secret from the terminal without echo (works even if stdin is not a tty)
read_token() {
    local prompt="$1"

    printf '%s\n' \
        'The token is not shown while you type or paste it. Press Enter when done.' \
        'Ctrl+C stops the setup here; nothing is lost, run the same command again to continue.' \
        > /dev/tty
    printf '%s' "$prompt" > /dev/tty
    # Echo is off while the token is typed. The traps turn it back on if Ctrl+C stops the script
    # (otherwise typed text stays invisible in this terminal until 'stty echo' or 'reset')
    trap 'stty echo < /dev/tty' EXIT
    trap 'printf "\nInterrupted, nothing is lost: run the same command again to continue\n" >&2; exit 130' INT TERM
    stty -echo < /dev/tty
    read -r token < /dev/tty
    stty echo < /dev/tty
    trap - EXIT INT TERM
    printf '\n' > /dev/tty
}

wait_enter() {
    printf 'Press Enter when done... ' > /dev/tty
    read -r _ < /dev/tty
}

# Queue a manual step, printed after setup is finalized
next_steps=""
next_step() {
    local step="$1"

    next_steps="${next_steps}  - $step
"
}

# Print the primary key fingerprint of the secret key whose UID matches this email
gpg_fingerprint() {
    local email="$1"

    gpg --list-secret-keys --with-colons "<$email>" 2>/dev/null | awk -F: '/^fpr:/{print $10; exit}'
}

# Append a line to a file unless the file already has exactly this line
add_line() {
    local file="$1"
    local line="$2"

    grep -qxF -- "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# Set a key in the work .gitconfig unless it is already set, so hand-edited values survive a re-run
# Uses $dirname set by setup()
# With --force as the third argument the key is set even when it already has a value
config_add() {
    local key="$1"
    local value="$2"
    local force="${3:-}"
    local config="$dirname/.gitconfig"

    if [ "$force" = --force ] || ! git config -f "$config" --get "$key" >/dev/null 2>&1; then
        git config -f "$config" "$key" "$value"
    fi
}

# ---- direnv definitions ----

# direnv config directory (used by both setup and cleanup)
direnv_conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/direnv"

# Append the direnv hook to an rc file unless an uncommented hook line is already there
add_direnv_hook() {
    local rc_file="$1"
    local hook="$2"

    mkdir -p "$(dirname "$rc_file")"
    if ! grep -q '^[^#]*direnv hook' "$rc_file" 2>/dev/null; then
        printf '\n# direnv\n%s\n' "$hook" >> "$rc_file"
        echo "Added direnv hook to $rc_file" >&2
    fi
}

# Remove the hook lines written by add_direnv_hook (exact-line match, other lines untouched)
remove_direnv_hook() {
    local rc_file="$1"

    [ -f "$rc_file" ] || return 0
    tmp=$(mktemp)
    grep -vxF                           \
        -e '# direnv'                   \
        -e 'eval "$(direnv hook zsh)"'  \
        -e 'eval "$(direnv hook bash)"' \
        "$rc_file" > "$tmp" ||:     # grep exits 1 when no lines are left
    cat "$tmp" > "$rc_file"         # cat instead of mv, keeps symlinked dotfiles intact
    rm -f "$tmp"
}

# Export a variable in the work .envrc unless .envrc already exports it,
# so a hand-edited value survives a re-run
# Uses $dirname set by setup(); .envrc is approved once in setup's finalize phase
env_set() {
    local name="$1"
    local value="$2"
    local envrc="$dirname/.envrc"

    if ! grep -Eq "^export $name=" "$envrc" 2>/dev/null; then
        echo "export $name=\"$value\"" >> "$envrc"
    fi
}

# Add a directory to PATH in the work .envrc (direnv's PATH_add) unless it is already added
# Uses $dirname set by setup()
env_path_add() {
    local dir="$1"

    add_line "$dirname/.envrc" "PATH_add \"$dir\""
}

# ---- end direnv definitions ----

# Print the host that glab/gh were logged in to (their own config, written at login),
# nothing for a setup without a host. Used by a re-run with only the directory
login_host() {
    local work_config="$1"
    local forge
    local config_dir

    forge=$(git config -f "$work_config" --get my.forge 2>/dev/null ||:)
    [ -n "$forge" ] || return 0
    config_dir=$(git config -f "$work_config" --get my.configDir)
    # The gh setup does not install yq
    if ! command -v yq >/dev/null 2>&1; then
        brew install yq >&2 || echo "brew install yq failed" >&2
    fi
    if [ "$forge" = glab ]; then
        yq '.hosts | keys | .[]' "$config_dir/config.yml"
    else
        yq 'keys | .[]' "$config_dir/hosts.yml"
    fi
}

cleanup() {
    [ -d "$target" ] || { echo "Directory $target does not exist" >&2; exit 1; }
    dirname=$(realpath "$target")
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

    # glab stores tokens in the macOS Keychain; logout removes them from there
    if [ "$(git config -f "$dirname/.gitconfig" --get my.forge 2>/dev/null)" = glab ]; then
        glab_config_dir=$(git config -f "$dirname/.gitconfig" --get my.configDir)
        for h in $(yq '.hosts | keys | .[]' "$glab_config_dir/config.yml"); do
            GLAB_CONFIG_DIR="$glab_config_dir" glab auth logout --hostname "$h" ||:
        done
    fi

    # Go module cache is read-only, make it removable
    [ -d "$dirname/.go" ] && chmod -R u+w "$dirname/.go"

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
    host="$arg3"
    # Re-run with only the directory: the email from the work .gitconfig, the host from the glab/gh login
    if [ -z "$email" ]; then
        email=$(git config -f "$target/.gitconfig" --get user.email 2>/dev/null ||:)
        host=$(login_host "$target/.gitconfig") || exit
        if [ -z "$email" ]; then
            echo "$target is not set up yet: run $0 $target <email> [host]" >&2
            exit 1
        fi
    fi
    # Normalize host: strip scheme and trailing slash
    host="${host#*://}"
    host="${host%/}"
    mkdir -p "$target"
    dirname=$(realpath "$target")

    # Detect the host type (only if a host was given) once; a re-run reuses the stored one,
    # so a temporary error page or SSO redirect cannot change it
    forge=$(git config -f "$dirname/.gitconfig" --get my.forge 2>/dev/null ||:)
    if [ -n "$host" ] && [ -z "$forge" ]; then
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://$host/api/v4/version" ||:)
        case "$code" in
            000|"") echo "Host $host is unreachable" >&2; exit 1 ;;
            200|401) forge=glab ;;
            *) forge=gh ;;
        esac
    fi

    # SSH key (not regenerated if it already exists)
    mkdir -p "$dirname/.ssh"
    chmod 700 "$dirname/.ssh"
    if [ ! -f "$dirname/.ssh/id_work" ]; then
        echo "Generating the SSH key, you will be asked to choose a passphrase" >&2
        ssh-keygen -t ed25519 -C "$email" -f "$dirname/.ssh/id_work"
        # A new key must be uploaded again
        git config -f "$dirname/.gitconfig" --unset my.sshKeyAdded 2>/dev/null ||:
    fi
    cat > "$dirname/.ssh/ssh-wrapper" <<EOF
#!/bin/sh
exec ssh -i "$dirname/.ssh/id_work" -o IdentitiesOnly=yes -o "UserKnownHostsFile=\"$dirname/.ssh/known_hosts\"" "\$@"
EOF
    chmod +x "$dirname/.ssh/ssh-wrapper"

    # Work git config (included from the global config via includeIf)
    config_add user.email "$email"
    config_add core.sshCommand "'$dirname/.ssh/ssh-wrapper'"

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
        # A new key replaces the old fingerprint and must be uploaded again.
        # --force: without it the old fingerprint of the lost key would stay and commits could not be signed
        config_add user.signingkey "$gpg_key" --force
        git config -f "$dirname/.gitconfig" --unset my.gpgKeyAdded 2>/dev/null ||:
    fi
    config_add user.signingkey "$gpg_key"
    config_add gpg.program "$dirname/.gnupg/gpg-wrapper"

    # Service repository: ignore everything, forbid commits
    git init -q -b work "$dirname" 2>/dev/null
    git -C "$dirname" symbolic-ref HEAD refs/heads/work
    # Its own exclude file, never the shared .gitignore below (git init may copy the template link)
    service_exclude="$dirname/.git/info/exclude"
    if [ -L "$service_exclude" ]; then
        rm "$service_exclude"
    fi
    add_line "$service_exclude" '*'
    cat > "$dirname/.git/hooks/pre-commit" <<'EOF'
#!/bin/sh
echo "Service repo, commits disabled" >&2
exit 1
EOF
    chmod +x "$dirname/.git/hooks/pre-commit"

    # Shared ignore rules for all work repositories: each repository's .git/info/exclude
    # is a symlink to $dirname/.gitignore; ~/.gitignore still applies via the global config
    shared_ignore="$dirname/.gitignore"
    touch "$shared_ignore"
    # New clones get the link from the template
    git_template="$dirname/.git-template"
    mkdir -p "$git_template/info"
    ln -sf "$shared_ignore" "$git_template/info/exclude"
    env_set GIT_TEMPLATE_DIR "$git_template"
    # On re-run: existing clones (and clones made without the template) get the link here;
    # an exclude file with own rules is left alone.
    # Skips the hidden directories in the root (tool data) and does not descend into repositories
    find "$dirname" -mindepth 1 -path "$dirname/.*" -prune -o -type d -exec test -d {}/.git \; -print -prune |
    while read -r repo; do
        git_dir="$repo/.git"
        exclude="$git_dir/info/exclude"
        [ -L "$exclude" ] && [ "$(readlink "$exclude")" = "$shared_ignore" ] && continue
        if grep -Eq '^[^#[:space:]]' "$exclude" 2>/dev/null; then
            echo "Not linking $exclude: it has own rules, move them to $shared_ignore" >&2
            continue
        fi
        mkdir -p "$git_dir/info"
        ln -sf "$shared_ignore" "$exclude"
    done
    # rg
    ripgreprc="$dirname/.ripgreprc"
    add_line "$ripgreprc" '--no-ignore-vcs'
    env_set RIPGREP_CONFIG_PATH "$ripgreprc"

    # gh/glab: separate config inside the directory + login (only if a host was given)
    if [ -n "$host" ]; then
        if [ "$forge" = glab ]; then
            glab_cli="$dirname/.glab-cli"
            mkdir -p "$glab_cli"
            chmod 700 "$glab_cli"
            config_add my.forge glab
            config_add my.configDir "$glab_cli"
            env_set GLAB_CONFIG_DIR "$glab_cli"
            env_set GITLAB_HOST "$host"
            # Skip the login while the stored token still works
            if ! GLAB_CONFIG_DIR="$glab_cli" glab auth status --hostname "$host" >/dev/null 2>&1; then
                cat >&2 <<EOF
glab login: create a personal access token with the 'api' scope at
https://$host/-/user_settings/personal_access_tokens, then paste it below.
EOF
                read_token "GitLab token (scope api): "
                printf '%s' "$token" | GLAB_CONFIG_DIR="$glab_cli" glab auth login --hostname "$host" --stdin
                unset token
                # glab seeds a new config with a gitlab.com host entry
                # (only right after the login, a gitlab.com login added later stays)
                if [ "$host" != gitlab.com ]; then
                    if ! command -v yq >/dev/null 2>&1; then
                        brew install yq || echo "brew install yq failed" >&2
                    fi
                    yq -i 'del(.hosts["gitlab.com"])' "$glab_cli/config.yml"
                fi
            fi
        else
            gh_dir="$dirname/.gh"
            mkdir -p "$gh_dir"
            chmod 700 "$gh_dir"
            config_add my.forge gh
            config_add my.configDir "$gh_dir"
            env_set GH_CONFIG_DIR "$gh_dir"
            # Skip the login while the stored token still works
            if ! GH_CONFIG_DIR="$gh_dir" gh auth status --hostname "$host" >/dev/null 2>&1; then
                cat >&2 <<EOF
gh login: create a personal access token with the 'repo' and 'read:org' scopes at
https://$host/settings/tokens, then paste it below.
EOF
                read_token "GitHub token (scopes repo, read:org): "
                printf '%s' "$token" | GH_CONFIG_DIR="$gh_dir" gh auth login \
                    --hostname "$host"                                       \
                    --insecure-storage                                       \
                    --git-protocol ssh                                       \
                    --with-token                                             \
                    || exit
                unset token
            fi
        fi
    fi

    # Global git config entry (outside the directory)
    git config --global "includeIf.gitdir:$dirname/.path" "$dirname/.gitconfig"

    # Public SSH key: the user must upload it to the work account
    # (asked until confirmed once, again after a new key is generated)
    if ! git config -f "$dirname/.gitconfig" --get my.sshKeyAdded >/dev/null 2>&1; then
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
        git config -f "$dirname/.gitconfig" my.sshKeyAdded true
    fi

    # Public GPG key: the user must upload it to the work account
    # (asked until confirmed once, again after a new key is generated)
    if ! git config -f "$dirname/.gitconfig" --get my.gpgKeyAdded >/dev/null 2>&1; then
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
        git config -f "$dirname/.gitconfig" my.gpgKeyAdded true
    fi

    # Go private modules
    if [ -n "$host" ]; then
        env_set GOPRIVATE           "$host"
        env_set GIT_SSH_COMMAND     "'$dirname/.ssh/ssh-wrapper'"
        env_set GIT_CONFIG_COUNT    1
        env_set GIT_CONFIG_KEY_0    "url.git@$host:.insteadOf"
        env_set GIT_CONFIG_VALUE_0  "https://$host/"
    fi
    # Go isolation
    env_set GOPATH      "$dirname/.go"
    env_set GOMODCACHE  "$dirname/.go/pkg/mod"
    env_set GOCACHE     "$dirname/.go/cache"
    env_set GOENV       "$dirname/.go/env"
    env_set GOBIN       "$dirname/.go/bin"
    env_path_add "$dirname/.go/bin"

    # direnv
    if ! command -v direnv >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install direnv || echo "brew install direnv failed" >&2
        else
            echo "direnv is missing and Homebrew was not found, install direnv manually" >&2
        fi
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

    # Claude Code
    env_set CLAUDE_CONFIG_DIR "$dirname/.claude-config"
    next_step "cd into $dirname, run 'claude' and log in with the work account"

    # ---- finalize: runs after all .envrc changes ----

    # Approve .envrc after its last change
    if command -v direnv >/dev/null 2>&1; then
        direnv allow "$dirname"
    fi

    printf '\n=== Initialization done ===\n' >&2
    if [ -n "$next_steps" ]; then
        printf 'Open a new terminal (so the direnv hook is active), then:\n%s' "$next_steps" >&2
    fi
}

case "$arg2" in
    --delete)
        if [ "$arg3" = --direnv ]; then
            remove_direnv=1
        elif [ -n "$arg3" ]; then
            echo "Unknown option: $arg3" >&2; exit 1
        fi
        cleanup
        ;;
    -*) echo "Unknown option: $arg2" >&2; exit 1 ;;
    *) setup ;;
esac
