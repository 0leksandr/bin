#!/bin/sh
sleep 20 && daemons 'light-mode all' 'conky-my' 'telegram' &
sleep 10 && beep && alert "test $0"                        &

# for command in \
#     "sleep 20 && daemons 'light-mode all' 'conky-my' 'telegram'" \
#     "sleep 10 && beep && alert 'test $0'" \
# ; do
#     $("$cmd") &
# done
