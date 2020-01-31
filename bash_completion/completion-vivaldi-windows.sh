#!/bin/sh
_complete_vivaldi_windows() {
    cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(compgen -W "move save" -- ${cur}) )
}
complete -F _complete_vivaldi_windows vivaldi-windows
