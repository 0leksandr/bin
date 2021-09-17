#!/bin/sh
set -e

# self-control
control=$(run-detached -q "sleep 50 && alert '$0 was not finished correctly'")

alert "$0: this is a test"

utils="$HOME/_/Programs/bin/utils"
$utils/bluetooth-off
mic-off
[ $(volume) -gt 40 ] && volume 40

# alert "$(ls /tmp/errors)"
errors init
# alert "$(ls /tmp/errors)"
echo "$0: [$(ls /tmp/errors)]" > "$HOME/_/test.txt"

# httpserver="http-server $HOME/_/localhost/http-server -a 127.0.0.1 -p 9473 --cors='Access-Control-Allow-Origin: *'"
daemons                                 \
    "errors listen"                     \
    "cronus $HOME/_/Programs/cronostab" \
    "light-mode all"                    \
    "conky-my"                          \
    "system-server"                     \
                                        &

sleep 5
run-detached "http-server $HOME/_/localhost/http-server -a 127.0.0.1 -p 9473 --cors='Access-Control-Allow-Origin: *'"
run-detached "$utils/battery-control.sh"
sleepy 00:00

sleep 5
start-closed slack 'Slack( \|.*)?'
start-closed telegram 'Telegram( \([0-9]+\))?'
start-closed skypeforlinux 'Skype'
# steam &

# sleep 10
# daemons        \
#     "dropbox"  \
#     "telegram" \
#                &

fkill "$control"
