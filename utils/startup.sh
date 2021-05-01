#!/bin/sh
set -e

# self-control
control=$(run-detached "sleep 50 && alert '$0 was not finished correctly'")

utils="$HOME/_/Programs/bin/utils"
$utils/bluetooth-off
mic-off
[ $(volume) -gt 40 ] && volume 40
light-mode all &
system-server &
$utils/errors-pipe.sh &

sleep 5
# vivaldi-my &
# $HOME/_/Programs/bin/battery-control.sh
conky-my &
sleepy 00:00
# systemctl restart systemd-udevd systemd-udevd-kernel.socket systemd-udevd-control.socket & # hotfix, see https://askubuntu.com/questions/1035528/ubuntu-18-04-systemd-udevd-uses-high-cpu-conflict-with-nvidia-graphics

sleep 5
cronus $HOME/_/Programs/cronostab &
# start-closed skypeforlinux 'Skype'
start-closed slack 'Slack( \|.*)?'
start-closed telegram 'Telegram( \([0-9]+\))?'
# steam &

sleep 10
daemons \
    "conky-my" \
    "cronus $HOME/_/Programs/cronostab" \
    "light-mode all" \
    "system-server" \
    "$utils/errors-pipe.sh" \
    "dropbox" \
    "telegram" \
&

fkill "$control"
