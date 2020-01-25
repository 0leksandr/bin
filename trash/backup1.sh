#!/bin/sh
reset
date
sudo rsync -aE --del --info=progress2,stats2,misc1,flist0 \
    --exclude=*/\.cache/ \
    --exclude=*/cache/ \
    --exclude=/dev/ \
    --exclude=/lost+found/ \
    --exclude=/media/ \
    --exclude=/mnt/ \
    --exclude=/proc/ \
    --exclude=/sys/ \
    --exclude=/tmp/ \
    / /media/nezhraba/Hard\ Disk\ Drive/Backup/L
rsync -aE --del --info=progress2,stats2,misc1,flist0 \
    --include=/C++/myLibs/*** \
    --include=/localhost/*** \
    --include=/Parallango/*** \
    --include=/Документи/*** \
    --include=/Книжки/*** \
    --include=/Музика/*** \
    --include=/Фото/*** \
    --exclude=* \
    /home/nezhraba/Data/ /media/nezhraba/Hard\ Disk\ Drive/Backup
beep
date
exit 0
