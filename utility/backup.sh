#!/bin/sh
set -e

reset
date-ft
dir="/media/$USER/Hard Disk Drive/Backup"

dirl="$dir/L"
mkdir -p "$dirl"
sudo r-sync                             \
    --exclude=*/\.cache/                \
    --exclude=*/cache/                  \
    --exclude=/dev/                     \
    --exclude=$HOME/_/                  \
    --exclude=$HOME/VirtualBox\ VMs/    \
    --exclude=$HOME/.local/share/Trash/ \
    --exclude=$HOME/.steam/             \
    --exclude=$HOME/.vagrant.d/         \
    --exclude=/lost+found/              \
    --exclude=/media/                   \
    --exclude=/mnt/                     \
    --exclude=/proc/                    \
    --exclude=/run/                     \
    --exclude=/sys/                     \
    --exclude=/tmp/                     \
    / "$dirl"
date-ft
hr

dir_="$dir/_"
mkdir -p "$dir_"
r-sync                                   \
    --exclude=/1/                        \
    --exclude=/[1]/                      \
    --exclude=/[12]/                     \
    --exclude=/[Private]/                \
    --exclude=/Programs/backups/         \
    --exclude=/Programs/vendor/clion*    \
    --exclude=/Programs/vendor/GoLand*   \
    --exclude=/Programs/vendor/PhpStorm* \
    --exclude=/Programs/vendor/pycharm*  \
    --exclude=/V/                        \
    --exclude=/Фільми/                   \
  --exclude=/localhost/symfony-test/test4/var/mysql/ \
    $HOME/_/ "$dir_"
date-ft
hr

beep

# r-sync $HOME/_/1/ "$dir1"
