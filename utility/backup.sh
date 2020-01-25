#!/bin/sh
reset                                                    && \
date-ft                                                  && \
dir="/media/$USER/Hard Disk Drive/Backup"                && \

test; if [ 1 -eq 2 ]; then
                                                            \
dirl="$dir/L"                                            && \
mkdir -p "$dirl"                                         && \
sudo r-sync                                                 \
    --exclude=*/\.cache/                                    \
    --exclude=*/cache/                                      \
    --exclude=/dev/                                         \
    --exclude=/home/$USER/_/                                \
    --exclude=/home/$USER/VirtualBox\ VMs                   \
    --exclude=/home/$USER/.local/share/Trash/               \
    --exclude=/home/$USER/.vagrant.d/                       \
    --exclude=/lost+found/                                  \
    --exclude=/media/                                       \
    --exclude=/mnt/                                         \
    --exclude=/proc/                                        \
    --exclude=/run/                                         \
    --exclude=/sys/                                         \
    --exclude=/tmp/                                         \
    / "$dirl"                                            && \
date-ft                                                  && \
                                                            \
dir_="$dir/_"                                            && \
mkdir -p "$dir_"                                         && \
r-sync                                                      \
    --exclude=/1/                                           \
    --exclude=/V/                                           \
    --exclude=/Фільми/                                      \
    --exclude=/Programs/backups/                            \
    --exclude=/Programs/vendor/clion*                       \
    --exclude=/Programs/vendor/PhpStorm*                    \
    --exclude=/Programs/vendor/pycharm*                     \
    /home/$USER/_/ "$dir_"                               && \
date-ft                                                  && \

test; fi
                                                            \
dir1="$dir/1"                                            && \
mkdir -p "$dir1"                                         && \
r-sync /home/$USER/_/1/ "$dir1"                          && \
date-ft                                                  && \
                                                            \
beep                                                     && \
exit 0
