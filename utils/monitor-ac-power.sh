#!/bin/sh
set -e

log(){ echo "$(date-ft): $1" >> ~/.temp/ac-power.log ;}

update() {
    case "$(acpi -a |sed -r 's/^Adapter 0: //')" in
        off-line)
            log "off"
            brightness --max 50
            cpu-set powersave
            ;;
        on-line)
            log "on"
            scene "$(scene actual)"
            cpu-set performance
            ;;
        *) exit 1 ;;
    esac
}

sleep 5  # -_-
update

# https://askubuntu.com/a/603794
acpi_listen |while read -r what junk; do
    if [ "$what" = "ac_adapter" ]; then
        update
    fi
done
