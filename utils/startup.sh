#!/bin/sh
set -e

# self-control
control=$(run-detached -q "sleep 50 && alert '$0 was not finished correctly'")

$HOME/_/Programs/bin/utils/bluetooth-off
mic-off
[ $(volume) -gt 40 ] && volume 40

errors init

daemons                                 \
    "errors listen"                     \
    "light-mode all"                    \
    "cronus $HOME/_/Programs/cronostab" \
    "conky-my"                          \
    "system-server"                     \
                                        &

sleep 5
# $HOME/_/Programs/bin/battery-control.sh
sleepy 00:00

sleep 5
# start-closed skypeforlinux 'Skype'
start-closed slack 'Slack( \|.*)?'
start-closed telegram 'Telegram( \([0-9]+\))?'
# steam &

sleep 10
daemons        \
    "dropbox"  \
    "telegram" \
               &

fkill "$control"
