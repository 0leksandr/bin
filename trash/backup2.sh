#!/bin/sh
reset
date +"%F %T"
date=`date +%F-%H%M`
dir="/media/$USER/Hard Disk Drive/Backup/$date"
dirl="$dir/L"
mkdir "$dir"
mkdir "$dirl"

# sudo r-sync \
sudo rsync -aE --info=progress2,stats2,misc1,flist0 --del \
    --exclude=*/\.cache/ \
    --exclude=*/cache/ \
    --exclude=/dev/ \
    --exclude=/home/$USER/_/ \
    --exclude=/home/$USER/Downloads/ \
    --exclude=/home/$USER/_/Programs/backups/ \
    --exclude=/home/$USER/_/Programs/clion* \
    --exclude=/home/$USER/_/Programs/pycharm* \
    --exclude=/home/$USER/_/Programs/PhpStorm* \
    --exclude=/home/$USER/VirtualBox\ VMs \
    --exclude=/home/$USER/.local/share/Trash/ \
    --exclude=/home/$USER/.vagrant.d/ \
    --exclude=/lost+found/ \
    --exclude=/media/ \
    --exclude=/mnt/ \
    --exclude=/proc/ \
    --exclude=/run/ \
    --exclude=/sys/ \
    --exclude=/tmp/ \
    / /media/$USER/Hard\ Disk\ Drive/Backup/$date/L

date +"%F %T"

# r-sync \
rsync -aE --info=progress2,stats2,misc1,flist0 --del \
    --include=/C++/myLibs/*** \
    --include=/localhost/*** \
    --include=/Parallango/*** \
    --include=/Programs/*** \
    --include=/Документи/*** \
    --include=/Картинки/*** \
    --include=/Книжки/*** \
    --include=/Музика/*** \
    --include=/Фото/*** \
    --exclude=* \
    /home/$USER/_/ /media/$USER/Hard\ Disk\ Drive/Backup/$date

date +"%F %T"

beep
exit 0
