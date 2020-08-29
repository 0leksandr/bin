#!/bin/sh

# $HOME/_/Programs/bin/utility/bluetooth-off
# mic-off
volume 40%
light-mode all &

sleep 5
# vivaldi-my &
# systemctl restart systemd-udevd systemd-udevd-kernel.socket systemd-udevd-control.socket & # hotfix, see https://askubuntu.com/questions/1035528/ubuntu-18-04-systemd-udevd-uses-high-cpu-conflict-with-nvidia-graphics
# $HOME/_/Programs/bin/battery-control.sh
conky-my &
sleepy 00:00

sleep 5
cronus $HOME/_/Programs/cronostab &
# start-closed skypeforlinux 'Skype'
start-closed slack 'Slack( \|.*)?'
start-closed telegram 'Telegram( \([0-9]+\))?'

sleep 10
daemons 'light-mode all' 'conky-my' 'telegram' &

alert "$0 finished"
