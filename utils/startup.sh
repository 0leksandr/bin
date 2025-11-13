#!/bin/sh
set -e

# self-control
control=$(run-detached -q "sleep 50 && alert '$0 was not finished correctly'")

log(){
    _log "$@"
    notify "$0: $@"
}
log "this is a test 1"

utils="$HOME/_/Programs/bin/utils"
local_utils="$HOME/_/Programs/local-bin/utils"
#bluetooth-off
mic-off

[ $(volume) -gt 40 ] && volume 40
#volume 40

log "this is a test 2"

errors init

log "this is a test 3"

daemons                                 \
    "errors listen"                     \
    "cronus $HOME/_/Programs/cronostab" \
    "brightness daemon"                 \
    "$local_utils/monitor-ac-power.sh"  \
    "system-server"                     \
    "scene _all"                        \
    "conky-my"                          \
                                        &
# $local_utils/external-display-settings

#supervisord --configuration=./supervisord.conf

imwheel --buttons "4 5"

# MAYBE: put into daemons
redshift -P -r -l "$(location latitude):$(location longitude)" -t "6500K:2100K" -m randr:crtc=0 &

log "this is a test 4"

sleep 5
run-detached "$utils/battery-control.sh"
#sleepy 00:00

sleep 5
#start-closed 1password "Lock Screen — 1Password"
#start-closed slack '(.+ - )?Slack'
start-closed telegram '.{0,2}(Telegram|Oleksandr Boiko)(.{1,2}\([0-9]+\))?'
#start-closed skypeforlinux 'Skype'
#steam &

# sleep 10
# daemons        \
#     "dropbox"  \
#     "telegram" \
#                &

fkill "$control"
