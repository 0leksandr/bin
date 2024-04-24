#!/bin/sh
set -e

# self-control
control=$(run-detached -q "sleep 50 && alert '$0 was not finished correctly'")

echo '' >> "$HOME/_/test.txt"
log (){
    echo "$0 $(date-ft): $@" >> "$HOME/_/test.txt"
    notify "$0: $@"
}
log "this is a test 1"

utils="$HOME/_/Programs/bin/utils"
#bluetooth-off
mic-off

#[ $(volume) -gt 40 ] && volume 40
volume 40

log "this is a test 2"

#notify "$(ls /tmp/errors)"
errors init
#notify "$(ls /tmp/errors)"
echo "$0: [$(ls /tmp/errors)]" > "$HOME/_/test.txt"

log "this is a test 3"

daemons                                 \
    "errors listen"                     \
    "cronus $HOME/_/Programs/cronostab" \
    "brightness daemon"                 \
    "$utils/monitor-ac-power.sh"        \
    "system-server"                     \
    "scene all"                         \
    "conky-my"                          \
    "$utils/external-display-settings"  \
                                        &

#supervisord --configuration=./supervisord.conf

imwheel --buttons "4 5"

# MAYBE: put into daemons
redshift -P -r -l "$(location latitude):$(location longitude)" -t "6500K:2100K" -m randr:crtc=0 &

log "this is a test 4"

sleep 5
run-detached "$utils/battery-control.sh"
sleepy 00:00

sleep 5
start-closed 1password "Lock Screen — 1Password"
#start-closed slack '(.+ - )?Slack'
start-closed telegram '(Telegram|Oleksandr Boiko)( \([0-9]+\))?'
#start-closed skypeforlinux 'Skype'
#steam &

# sleep 10
# daemons        \
#     "dropbox"  \
#     "telegram" \
#                &

fkill "$control"
