#!/bin/sh

$HOME/_/Programs/bin/utility/bluetooth-off
mic-off
# volume 40%
light-mode all &
close-browser-tab &

sleep 5
# vivaldi-my &
# $HOME/_/Programs/bin/battery-control.sh
conky-my &
sleepy 00:00

sleep 5
cronus $HOME/_/Programs/cronostab &
# start-closed skypeforlinux 'Skype'
start-closed slack 'Slack( \|.*)?'
start-closed telegram 'Telegram( \([0-9]+\))?'

sleep 10
daemons 'light-mode all' 'conky-my' 'telegram' 'cronus' 'close-browser-tab' &

alert "$0 finished"
