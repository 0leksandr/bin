#!/bin/sh
set -e

log(){ echo "$(date-ft): $1" >> ~/.temp/ac-power.log ;}

status(){ acpi -a |sed -r 's/^Adapter 0: //' ;}

update() {
    case "$1" in
        off-line)
            log "off"
            brightness set power 50
            cpu-set powersave
            ;;
        on-line)
            log "on"
            brightness set power 100
            cpu-set performance
            ;;
        *) exit 1 ;;
    esac
}

update "$(status)"
sleep 5  # let `scene` do its job -_-
update "$(status)"

prev_status="$(status)"
# https://askubuntu.com/a/603794
acpi_listen |while read -r what junk; do
    if [ "$what" = "ac_adapter" ]; then
        new_status="$(status)"
        if [ "$new_status" != "$prev_status" ]; then
            update "$new_status"
            prev_status="$new_status"
        fi
    fi
done
