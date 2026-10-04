#!/bin/sh
set -eu

# Setup:   $0 <directory> <email> [GitLab / GitHub Enterprise / github.com host]
# Cleanup: $0 <directory>
#
# Examples:
#   $0 ~/work/ me@company.com                  (no gh/glab setup)
#   $0 ~/work/ me@company.com git.company.com  (self-hosted GitLab or GHE)
#   $0 ~/work/ me@company.com github.com       (separate work account on github.com)
#   $0 ~/work/                                 (cleanup)
target="${1:?Specify a directory (usage: $0 <directory> <email> [host])}"
arg2="${2:-}"

# Read a secret from the terminal without echo (works even if stdin is not a tty)
read_token() {
    printf '%s' "$1" > /dev/tty
    stty -echo < /dev/tty
    read -r token < /dev/tty
    stty echo < /dev/tty
    printf '\n' > /dev/tty
}

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
    ssh-add -d "$dirname/.ssh/id_work" 2>/dev/null || true

    # Remove the includeIf entry from the global git config
    git config --global --remove-section "includeIf.gitdir:$dirname/" 2>/dev/null || true

    rm -rf "$dirname"

    echo "Done. Left to do manually:"
    echo "  - delete the public key on GitHub/GitLab (Settings -> SSH keys)"
    echo "  - revoke the personal access token created for glab/gh"
    echo "  - optionally delete the id_work entry in Keychain Access"
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
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://$host/api/v4/version" || true)
        case "$code" in
            000|"") echo "Host $host is unreachable" >&2; exit 1 ;;
            200|401) forge=gitlab ;;
            *) forge=github ;;
        esac
    fi

    # SSH key (not regenerated if it already exists)
    mkdir -p "$dirname/.ssh"
    chmod 700 "$dirname/.ssh"
    [ -f "$dirname/.ssh/id_work" ] || ssh-keygen -t ed25519 -C "$email" -f "$dirname/.ssh/id_work"

    # Work git config (included from the global config via includeIf)
    cat > "$dirname/.gitconfig" <<EOF
[user]
    email = $email
[core]
    sshCommand = ssh -i $dirname/.ssh/id_work -o IdentitiesOnly=yes -o UserKnownHostsFile=$dirname/.ssh/known_hosts
EOF

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
            read_token "GitLab token (scope api): "
            printf '%s' "$token" | GLAB_CONFIG_DIR="$dirname/.config/glab-cli" glab auth login --hostname "$host" --stdin
            unset token
        else
            mkdir -p "$dirname/.config/gh"
            git config -f "$dirname/.gitconfig" my.forge gh
            git config -f "$dirname/.gitconfig" my.configDir "$dirname/.config/gh"
            read_token "GitHub token (scopes repo, read:org): "
            printf '%s' "$token" | GH_CONFIG_DIR="$dirname/.config/gh" gh auth login --hostname "$host" --insecure-storage -p ssh --with-token
            unset token
        fi
    fi

    # The only entry outside the directory
    git config --global "includeIf.gitdir:$dirname/.path" "$dirname/.gitconfig"

    # Public key to upload to GitHub/GitLab
    cat "$dirname/.ssh/id_work.pub"
}

case "$arg2" in
    "") cleanup ;;
    -*) echo "Unknown option: $arg2" >&2; exit 1 ;;
    *) setup "$@" ;;
esac
